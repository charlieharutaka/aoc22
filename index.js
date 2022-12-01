const process = require("node:process");
const childProcess = require("node:child_process");
const util = require("node:util");
const fs = require("node:fs/promises");
const path = require("node:path");
const glob = util.promisify(require("glob"));
const exec = util.promisify(childProcess.exec);

async function convertWasm() {
  for (const inputFile of await glob("**/*.wat")) {
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
}

async function clearWasm() {
  for (const target of await glob("**/*.wasm")) {
    await fs.rm(target);
  }
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
    const inputOffset = 0x8000; // 32KB data size
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

    console.log(`Part 1: ${part1()}`);
    console.log(`Part 2: ${part2()}`);
  } catch (error) {
    if (error.code === "ENOENT") {
      console.log("=== ERROR ===");
      console.log(`Could not open file ${error.path}`);
      console.log("=============");
    } else throw error;
  }
})(process.argv[2]).then(() => process.exit(0));
