const Web3 = require('web3');

function encodeStorageBatchParam(ipldHashArr) {
  const addrBytes = '0x692a70d2e424a56d2c6c27aa97d1a86395877b3a'.slice(2);
  const lenBytes = ipldHashArr.length.toString(16).padStart(4, '0');
  const ipldHashBytesArr = ipldHashArr.map(ipldHash => Web3.utils.asciiToHex(ipldHash).slice(2));
  return `0x${[addrBytes, lenBytes, ...ipldHashBytesArr].join('')}`;
}

module.exports = {
  encodeStorageBatchParam,
};
