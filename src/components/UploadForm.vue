<template>
  <v-form @submit.prevent="onSubmit">
    <v-container grid-list-xl>
      <v-layout wrap>
        <v-flex xs12>
          <v-alert type="info">
            以區塊鏈儲存你的圖片，使之不能竄改，刪之不盡，遍地開花。
            <br v-if="$vuetify.breakpoint.name !== 'xs'">
            請務必合法使用，注意版權。
          </v-alert>
          <v-alert
            :value="!!web3Error"
            prominent
            type="error"
          >{{ web3Error }}</v-alert>
          <v-alert
            :value="!!genericError"
            prominent
            type="error"
          >{{ genericError }}</v-alert>
        </v-flex>
        <v-flex class="d-flex" xs12>
          <v-card v-if="preview" class="mr-4" width="56" height="56" flat>
            <v-img :src="preview" width="100%" height="100%" />
          </v-card>
          <v-file-input
            v-model="file"
            label="Image Upload"
            accept="image/*"
            outlined
            @change="onChangeFile"
          ></v-file-input>
        </v-flex>
        <v-flex
          xs12
          md4
        >
          <v-menu
            v-model="isDatePickerDialogOpen"
            :close-on-content-click="false"
            :nudge-right="40"
            transition="scale-transition"
            offset-y
            full-width
            min-width="290px"
          >
            <template v-slot:activator="{ on }">
              <v-text-field
                v-model="dateTime"
                label="Date Time"
                outlined
                readonly
                required
                v-on="on"
              ></v-text-field>
            </template>
            <v-date-picker
              v-model="dateTime"
              label="Date Time"
              required
              @input="isDatePickerDialogOpen = false"
            ></v-date-picker>
          </v-menu>
        </v-flex>

        <v-flex
          xs12
          md4
        >
          <v-text-field
            v-model="latitude"
            label="Latitude"
            outlined
            required
          ></v-text-field>
        </v-flex>

        <v-flex
          xs12
          md4
        >
          <v-text-field
            v-model="longitude"
            label="Longitude"
            outlined
            required
          ></v-text-field>
        </v-flex>

        <v-flex
          xs12
          md4
        >
          <v-text-field
            v-model="author"
            label="Author"
            outlined
            required
          ></v-text-field>
        </v-flex>

        <v-flex
          xs12
          md5
        >
          <v-text-field
            v-model="description"
            label="Description"
            outlined
            required
          ></v-text-field>
        </v-flex>

        <v-flex
          xs12
          md3
        >
          <v-select
            v-model="license"
            :items="licenseOptions"
            label="License"
            outlined
            required
          >
            <template v-if="license.startsWith('http')" #append-outer>
              <v-btn
                style="margin-top: -8px"
                :href="license"
                target="_blank"
                small
                icon
              ><v-icon>mdi-help-circle</v-icon></v-btn>
            </template>
          </v-select>
        </v-flex>

        <v-flex
          class="text-center text-md-right"
          xs12
        >
          <v-btn
            type="submit"
            color="primary"
            :disabled="web3Error || !file"
            :loading="isLoading"
            large
          >{{ isRetrying ? 'Retry' : 'Upload' }}</v-btn>
        </v-flex>

      </v-layout>
    </v-container>
    <v-snackbar
      :value="isSubmitting"
      :timeout="0"
      :multi-line="true"
    >
      <v-progress-circular
        indeterminate
        color="primary"
      ></v-progress-circular>
      <v-flex class="text-center">
        <span v-if="submitState === 0">Uploading file to IPFS...</span>
        <span v-else-if="submitState === 1">Uploading metadata to IPLD</span>
        <span v-else-if="submitState === 2">Signing to Ethereum...</span>
        <span v-else-if="submitState === 3">Pinning...</span>
      </v-flex>
    </v-snackbar>
  </v-form>
</template>

<script>
import Web3 from 'web3';
import { abi, address } from '../constant/contract';
import {
  removeExif,
  processEXIF,
} from '../util/exif';
import { processDateTime } from '../util/misc';

const ipfsClient = require('ipfs-http-client');

const ipfs = ipfsClient({ host: 'ipfs.infura.io', port: '5001', protocol: 'https' });

const LICENSE_OPTIONS = [
  { text: 'CC0', value: 'https://creativecommons.org/publicdomain/zero/1.0' },
  { text: 'CC BY', value: 'https://creativecommons.org/licenses/by/4.0' },
  { text: 'CC BY-SA', value: 'https://creativecommons.org/licenses/by-sa/4.0' },
  { text: 'CC BY-NC', value: 'https://creativecommons.org/licenses/by-nc/4.0' },
  { text: 'CC BY-ND', value: 'https://creativecommons.org/licenses/by-nd/4.0' },
  { text: 'CC BY-NC-SA', value: 'https://creativecommons.org/licenses/by-nc-sa/4.0' },
  { text: 'CC BY-NC-ND', value: 'https://creativecommons.org/licenses/by-nc-nd/4.0' },
  { text: 'Copyrighted', value: 'Copyrighted' },
  { text: 'Unknown', value: 'Unknown' },
];

export default {
  data: () => ({
    hasExif: false,
    hasWeb3Inited: false,
    isSubmitting: false,
    isProcessingEXIF: false,
    isDatePickerDialogOpen: false,
    isRetrying: false,

    submitState: 0,
    ipfsResult: {},
    ipld: {},
    txHash: '',

    file: null,
    preview: null,
    dateTime: processDateTime(new Date()),
    latitude: 0,
    longitude: 0,
    description: '',
    author: '',
    license: LICENSE_OPTIONS[0].value,

    web3: null,
    web3Error: '',
    genericError: '',
  }),
  computed: {
    licenseOptions() {
      return LICENSE_OPTIONS;
    },
    isLoading() {
      return this.isProcessingEXIF || this.isSubmitting;
    },
    uploadFormat() {
      return {
        '@context': 'https://schema.org',
        '@type': 'Photograph',
        '@id': '',
        dateCreated: processDateTime(this.dateTime),
        datePublished: processDateTime(new Date()),
        license: this.license,
        description: this.description,
        author: this.author,
        contentLocation: {
          '@type': 'Place',
          geo: {
            '@type': 'GeoCoordinates',
            latitude: this.latitude,
            longitude: this.longitude,
          },
        },
      };
    },
  },
  mounted() {
    this.setUpEth();
  },
  methods: {
    loadPreview(file) {
      if (file) {
        const reader = new FileReader();
        reader.addEventListener('load', () => {
          this.preview = reader.result;
        }, false);
        reader.readAsDataURL(file);
      } else {
        this.preview = null;
      }
    },
    async processEXIF(file) {
      this.hasExif = false;
      this.isProcessingEXIF = true;
      try {
        const info = await processEXIF(file);
        if (info) {
          this.hasExif = true;
          // TODO: iterate field list instead of hardcode
          this.author = info.author;
          this.dateTime = info.dateTime;
          this.latitude = info.latitude;
          this.longitude = info.longitude;
          this.description = info.description;
        }
      } catch (err) {
        console.error(err);
      } finally {
        this.isProcessingEXIF = false;
      }
    },
    onChangeFile(file) {
      this.processEXIF(file);
      this.loadPreview(file);
    },
    async onSubmit() {
      try {
        if (!this.hasWeb3Inited) await this.setUpEth();
        const [from] = await this.web3.eth.getAccounts();
        if (!from) {
          this.web3Error = 'Please unlock your wallet';
          return;
        }
        this.isSubmitting = true;
        let { file } = this;
        if (this.hasExif) {
          file = await removeExif(this.file);
          if (!file) {
            ({ file } = this);
          }
        }
        if (this.submitState < 1) {
          this.ipfsResult = await ipfs.add(file, { pin: false });
          this.submitState = 1;
        }
        const ipfsHash = this.ipfsResult[0].hash;
        const input = {
          ...this.uploadFormat,
          datePublished: processDateTime(new Date()),
          '@id': `ipfs://${ipfsHash}`,
        };
        if (this.submitState < 2) {
          this.ipld = await ipfs.dag.put(input, {
            format: 'dag-cbor',
            hashAlg: 'sha2-256',
          });
          this.submitState = 2;
        }
        const ipldHash = this.ipld.toBaseEncodedString();
        if (this.submitState < 3) {
          this.txHash = await this.ethUpload(ipldHash);
          this.submitState = 3;
        }
        if (this.submitState < 4) {
          const promises = [
            ipfs.pin.add(ipfsHash, { recursive: false }),
            ipfs.pin.add(ipldHash, { recursive: false }),
          ];
          await Promise.all(promises);
          this.submitState = 4;
        }
        this.submitState = 0;
        this.$router.push({ name: 'view', params: { hash: ipldHash }, query: { tx: this.txHash } });
        this.isSubmitting = false;
      } catch (err) {
        console.error(err);
        this.genericError = err.msg || err;
        this.isRetrying = true;
        this.isSubmitting = false;
      }
    },
    async setUpEth() {
      this.web3Error = '';
      if (window.ethereum) {
        const { ethereum } = window;
        this.web3 = new Web3(ethereum);
        try {
          await ethereum.enable();
          const network = await this.web3.eth.net.getNetworkType();
          if (network !== 'main') {
            this.web3Error = 'Please switch to Main Network';
            return;
          }
          this.hasWeb3Inited = true;
          this.Storage = new this.web3.eth.Contract(abi, address);
        } catch (err) {
          this.web3Error = 'Please accept the connect request in Metamask';
          console.error(err);
        }
      } else {
        this.web3Error = 'Please install MetaMask https://metamask.io/';
      }
    },
    async ethUpload(inputData) {
      const [from] = await this.web3.eth.getAccounts();
      let data = inputData;
      if (typeof data !== 'string') {
        data = JSON.stringify(data);
      }
      const send = this.Storage.methods.store(data).send({
        from,
      });
      return new Promise((resolve, reject) => send
        .once('transactionHash', resolve)
        .on('error', reject));
    },
  },
};
</script>
