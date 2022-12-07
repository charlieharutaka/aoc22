const process = require("node:process");
const childProcess = require("node:child_process");
const util = require("node:util");
const fs = require("node:fs/promises");
const path = require("node:path");
const glob = util.promisify(require("glob"));
const exec = util.promisify(childProcess.exec);
const { performance } = require("node:perf_hooks");

async function convertWasm() {
  const inputFiles = await glob("**/*.wat");
  for (const inputFile of inputFiles) {
    const inputPath = path.parse(inputFile);
    const outputPath = { ...inputPath, base: "", ext: ".wasm" };
    const outputFile = path.format(outputPath);
    try {
      await exec(`wat2wasm ${inputFile} -o ${outputFile}`);
    } catch (error) {
      console.log(`=== ERROR [ in ${inputFile} ] ===`);
      console.log(error.stderr);
      console.log("=================================");
      process.exit(1);
    }
  }
  return inputFiles.length;
}

async function clearWasm() {
  const targets = await glob("**/*.wasm");
  for (const target of targets) {
    await fs.rm(target);
  }
  return targets.length;
}

async function loadWasmUtils(importObject) {
  const utilsFile = path.resolve(__dirname, "utils/utils.wasm");
  const utilsBuffer = await fs.readFile(utilsFile);
  return (await WebAssembly.instantiate(utilsBuffer, importObject)).instance
    .exports;
}

(async function main(folder) {
  if (!folder) {
    throw new Error("Must provide a folder to execute");
  }

  await clearWasm();
  await convertWasm();

  const inputFile = path.resolve(__dirname, folder, "input.txt");
  const wasmFile = path.resolve(__dirname, folder, "main.wasm");

  try {
    const inputBuffer = await fs.readFile(inputFile);
    const inputByteBuffer = new Uint8Array(inputBuffer);
    const inputOffset = 0x2000; // 8KB data section size
    const inputLength = inputBuffer.byteLength;

    const wasmBuffer = await fs.readFile(wasmFile);
    const wasmMemory = new WebAssembly.Memory({ initial: 10 }); // 10x64KB pages (640KB)
    const wasmMemoryBuffer = new Uint8Array(wasmMemory.buffer, inputOffset);
    for (let i = 0; i < inputByteBuffer.byteLength; i++) {
      wasmMemoryBuffer[i] = inputByteBuffer[i];
    }

    const importObject = {
      js: {
        mem: wasmMemory,
        printint: (x, radix = 10) => console.log(x.toString(radix)),
        putchar: (x) => process.stdout.write(String.fromCharCode(x)),
      },
      global: {
        inputOffset: new WebAssembly.Global({ value: "i32" }, inputOffset),
        inputLength: new WebAssembly.Global({ value: "i32" }, inputLength),
      },
    };

    const wasmUtils = await loadWasmUtils(importObject);
    const { part1, part2 } = (
      await WebAssembly.instantiate(wasmBuffer, {
        ...importObject,
        utils: wasmUtils,
      })
    ).instance.exports;

    // warmup
    const oldLog = console.log;
    const oldWrite = process.stdout.write;
    console.log = () => {};
    process.stdout.write = () => {};
    performance.mark("warmup:part1");
    for (let i = 0; i < 10; i++) part1();
    performance.mark("warmup:part1:complete");
    console.log = oldLog;
    process.stdout.write = oldWrite;

    const warmup1Duration = performance.measure(
      "",
      "warmup:part1",
      "warmup:part1:complete"
    ).duration;
    console.log(`Part 1 Warmup: ${(warmup1Duration * 1000).toFixed(2)}us`);

    // execute part 1
    performance.mark("execute:part1");
    const part1result = part1();
    performance.mark("finish:part1");
    const part1duration = performance.measure(
      "",
      "execute:part1",
      "finish:part1"
    ).duration;
    console.log(
      `Part 1: ${part1result} (${(part1duration * 1000).toFixed(2)}us)`
    );

    // warmup
    console.log = () => {};
    process.stdout.write = () => {};
    performance.mark("warmup:part2");
    for (let i = 0; i < 10; i++) part2();
    performance.mark("warmup:part2:complete");
    console.log = oldLog;
    process.stdout.write = oldWrite;
    const warmup2Duration = performance.measure(
      "",
      "warmup:part2",
      "warmup:part2:complete"
    ).duration;
    console.log(`Part 2 Warmup: ${(warmup2Duration * 1000).toFixed(2)}us`);

    // execute part 2
    performance.mark("execute:part2");
    const part2result = part2();
    performance.mark("finish:part2");
    const part2duration = performance.measure(
      "",
      "execute:part2",
      "finish:part2"
    ).duration;
    console.log(
      `Part 2: ${part2result.toString()} (${(part2duration * 1000).toFixed(
        2
      )}us)`
    );

    const buffer = new Uint8Array(wasmMemory.buffer, 0x10000);
    console.log([...buffer.slice(0, 0x30)].map((x) => String.fromCharCode(x)));
  } catch (error) {
    if (error.code === "ENOENT") {
      console.log("=== ERROR ===");
      console.log(`Could not open file ${error.path}`);
      console.log("=============");
    } else throw error;
  }
})(process.argv[2]).then(() => process.exit(0));
