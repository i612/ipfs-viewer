<template>
  <v-container class="view-page py-8">
    <v-card
      class="mx-auto"
      flat
      outlined
    >
      <div
        v-if="ipfsHash"
        class="image-wrapper"
      >
        <img
          v-if="imageSource"
          :src="imageSource"
        >
      </div>
      <v-toolbar flat>
        <v-tooltip bottom>
          <template v-slot:activator="{ on }">
            <span class="font-weight-bold" v-on="on">
              ISCN <br v-if="$vuetify.breakpoint.name === 'xs'">Properties
            </span>
          </template>
          <span>
            International Standard Content Number,<br>
            a worldwide unique number and metadata to identify a content
          </span>
        </v-tooltip>
        <v-spacer />
        <v-menu offset-y>
          <template v-slot:activator="{ on }">
            <v-btn
              v-on="on"
              color="blue darken-2"
              :small="$vuetify.breakpoint.name === 'xs'"
              outlined
            >
              IPFS Nodes
              <v-icon right>mdi-monitor-multiple</v-icon>
            </v-btn>
          </template>
          <v-list dense>
            <v-list-item
              v-for="(item, index) in ipfsGateways"
              :key="index"
              :href="`${item.link}/${ipfsHash}`"
              target="_blank"
            >
              <v-list-item-icon>
                <v-icon class="green--text text--accent-4" small>mdi-monitor</v-icon>
              </v-list-item-icon>
              <v-list-item-title>View via {{ item.title }}</v-list-item-title>
              <v-list-item-action>
                <v-icon small>mdi-arrow-right</v-icon>
              </v-list-item-action>
            </v-list-item>
          </v-list>
        </v-menu>
        <v-btn
          v-if="isSupportShare"
          icon
          @click="onShare"
        >
          <v-icon>mdi-share</v-icon>
        </v-btn>
      </v-toolbar>
      <v-divider />
      <v-list>
        <v-list-item>
          <v-list-item-content>
            <v-list-item-title class="font-weight-bold">IPFS Hash</v-list-item-title>
            <v-list-item-subtitle>
              <a
                :href="imageSource"
                target="_blank"
                style="font-family: monospace"
              >{{ properties['@id'] }}</a>
            </v-list-item-subtitle>
          </v-list-item-content>
        </v-list-item>

        <v-list-item>
          <v-list-item-content>
            <v-list-item-title class="font-weight-bold">
              Blockchain Transaction Record
            </v-list-item-title>
            <v-list-item-subtitle>
              <a
                :href="txHashUrl"
                target="_lank"
                style="font-family: monospace"
              >{{ properties.txHash }}</a>
            </v-list-item-subtitle>
          </v-list-item-content>
        </v-list-item>

        <v-list-item>
          <v-list-item-content>
            <v-list-item-title class="font-weight-bold">
              Blockchain Transaction Time
            </v-list-item-title>
            <v-list-item-subtitle>{{ properties.blockTime }}</v-list-item-subtitle>
          </v-list-item-content>
        </v-list-item>

        <v-list-item v-if="properties.author">
          <v-list-item-content>
            <v-list-item-title class="font-weight-bold">Creator</v-list-item-title>
            <v-list-item-subtitle>{{ properties.author }}</v-list-item-subtitle>
          </v-list-item-content>
        </v-list-item>

        <v-list-item>
          <v-list-item-content>
            <v-list-item-title class="font-weight-bold">License</v-list-item-title>
            <v-list-item-subtitle>
              <a
                v-if="properties.license && properties.license.startsWith('http')"
                :href="properties.license"
                target="_blank"
              >{{ properties.license }}</a>
              <template v-else>{{ properties.license }}</template>
            </v-list-item-subtitle>
          </v-list-item-content>
        </v-list-item>

        <v-row no-gutters>
          <v-col>
            <v-list-item>
              <v-list-item-content>
                <v-list-item-title class="font-weight-bold">Date Created</v-list-item-title>
                 <v-list-item-subtitle>{{ properties.dateCreated }}</v-list-item-subtitle>
              </v-list-item-content>
            </v-list-item>
          </v-col>
          <!-- <v-col>
            <v-list-item>
              <v-list-item-content>
                <v-list-item-title class="font-weight-bold">Date Published</v-list-item-title>
                 <v-list-item-subtitle>{{ properties.datePublished }}</v-list-item-subtitle>
              </v-list-item-content>
            </v-list-item>
          </v-col> -->
        </v-row>

        <v-list-item v-if="properties.description">
          <v-list-item-content>
            <v-list-item-title class="font-weight-bold">Description</v-list-item-title>
            <div class="v-list-item__action-text body-2">{{ properties.description }}</div>
          </v-list-item-content>
        </v-list-item>

        <v-list-item v-if="latitude && longitude">
          <v-list-item-content>
            <v-list-item-title class="font-weight-bold">Content Location</v-list-item-title>
            <v-list-item-subtitle>
              <v-responsive class="mt-2" :aspect-ratio="16/9">
                <iframe
                  :src="`https://www.google.com/maps/embed/v1/place?key=${GOOGLE_MAP_KEY}&center=${latitude},${longitude}&q=${latitude},${longitude}&zoom=18&maptype=roadmap`"
                  width="100%"
                  height="100%"
                  frameborder="0"
                />
              </v-responsive>
            </v-list-item-subtitle>
          </v-list-item-content>
        </v-list-item>

        <v-row no-gutters>
          <v-col>
            <v-list-item>
              <v-list-item-content>
                <v-list-item-title class="font-weight-bold">Type</v-list-item-title>
                <v-list-item-subtitle>{{ properties['@type'] }}</v-list-item-subtitle>
              </v-list-item-content>
            </v-list-item>
          </v-col>
          <v-col>
            <v-list-item>
              <v-list-item-content>
                <v-list-item-title class="font-weight-bold">Context</v-list-item-title>
                <v-list-item-subtitle>{{ properties['@context'] }}</v-list-item-subtitle>
              </v-list-item-content>
            </v-list-item>
          </v-col>
        </v-row>
      </v-list>
    </v-card>
  </v-container>
</template>

<script>
import axios from 'axios';
import Web3 from 'web3';
import { storageAbi } from '../constant/contract';
import { ethEndpoint, ethStorageContractAddr, ethEventFromBlock } from '../../config';

const web3 = new Web3(new Web3.providers.HttpProvider(ethEndpoint));
const Storage = new web3.eth.Contract(storageAbi, ethStorageContractAddr);

export default {
  name: 'ContentView',
  data() {
    return {
      GOOGLE_MAP_KEY: process.env.GOOGLE_MAP_KEY || 'AIzaSyDHzJiFMF0LqNG3mEb1paNDvSOW-_txAWY',
      ipfsGateways: [
        { title: 'ipfs.io', link: 'https://ipfs.io/ipfs' },
        { title: 'Cloudflare', link: 'https://cloudflare-ipfs.com/ipfs' },
        { title: 'Infura', link: 'https://ipfs.infura.io/ipfs' },
        { title: 'Nine Tales of Ninja', link: 'https://ninetailed.ninja/ipfs' },
        { title: 'Global Upload', link: 'https://ipfs.globalupload.io' },
        { title: 'Siderus', link: 'https://siderus.io/ipfs' },
        { title: 'Eternum', link: 'https://ipfs.eternum.io/ipfs' },
        { title: 'Hardbin', link: 'https://hardbin.com/ipfs' },
        { title: 'Pinata', link: 'https://gateway.pinata.cloud/ipfs' },
        { title: 'Temporal', link: 'https://gateway.temporal.cloud/ipfs' },
        { title: 'Privacy Tools', link: 'https://ipfs.privacytools.io/ipfs' },
      ],
      metadata: {},
      txHash: this.$route.query.tx,
      ipfsHash: '',
      txTimeStamp: 0,
      ipfsHost: 'https://ipfs.infura.io/ipfs',
    };
  },
  computed: {
    isSupportShare() {
      return !!window.navigator.share;
    },
    hash() {
      return this.$route.params.hash;
    },
    txHashUrl() {
      if (this.txHash) return `https://etherscan.io/tx/${this.txHash}`;
      return `https://etherscan.io/address/${ethStorageContractAddr}`;
    },
    imageSource() {
      if (!this.ipfsHash) return '';
      return `${this.ipfsHost}/${this.ipfsHash}`;
    },
    properties() {
      return {
        txHash: this.txHash ? this.txHash : 'pending or not found',
        blockTime: this.txTimeStamp ? new Date(this.txTimeStamp) : 'pending or not found',
        ...this.metadata,
      };
    },
    latitude() {
      if (!this.metadata || !this.metadata.contentLocation) return undefined;
      const { latitude } = this.metadata.contentLocation.geo;
      if (typeof latitude === 'number') return latitude;
      if (!latitude) return 0;
      const numberLength = latitude.length - 1;
      const numberValue = Number(latitude.substring(0, numberLength));
      if (latitude[numberLength].toUpperCase() === 'S') {
        return -1 * numberValue;
      }
      return numberValue;
    },
    longitude() {
      if (!this.metadata || !this.metadata.contentLocation) return undefined;
      const { longitude } = this.metadata.contentLocation.geo;
      if (typeof longitude === 'number') return longitude;
      if (!longitude) return 0;
      const numberLength = longitude.length - 1;
      const numberValue = Number(longitude.substring(0, numberLength));
      if (longitude[numberLength].toUpperCase() === 'W') {
        return -1 * numberValue;
      }
      return numberValue;
    },
  },
  async mounted() {
    if (this.hash) {
      const { data: ipldData } = await axios.get(`https://ipfs.infura.io:5001/api/v0/dag/get?arg=${this.hash}`);
      if (ipldData['@id']) {
        this.ipfsHash = ipldData['@id'].replace('ipfs://', '');
        this.metadata = ipldData;
      } else {
        this.ipfsHash = this.hash;
      }
      this.pingForIPFSHost();
      const id = web3.utils.sha3(this.hash);
      const events = await Storage.getPastEvents('Data', {
        fromBlock: ethEventFromBlock,
        filter: { id },
      });
      const event = events.find(e => e.returnValues.data === this.hash);
      if (event) {
        this.txHash = event.transactionHash;
        this.txTimeStamp = Number.parseInt(event.returnValues.timestamp, 10) * 1000;
      } else {
        this.txHash = '';
      }
    }
    if (this.$route.query.tx) {
      const { tx, ...query } = this.$route.query;
      this.$router.replace({ query });
    }
  },
  methods: {
    onShare() {
      if (window.navigator.share) {
        window.navigator.share({
          title: `${this.metadata.description || 'Image'} shared via i612`,
          url: window.location.href,
        });
      }
    },
    async pingForIPFSHost() {
      const targets = this.ipfsGateways.slice(0, 3).map(
        // inverted use of Promise.all, accept error and throw success
        i => axios.head(`${i.link}/${this.ipfsHash}`)
          .catch(() => true)
          .then((res) => {
            if (res.status > 199 && res.status < 300) {
              throw res;
            }
            return true;
          }),
      );
      try {
        await Promise.all(targets);
      } catch (err) {
        // quickest res to throw is fastest success
        if (err.request && err.request.responseURL) {
          const res = err;
          this.ipfsHost = res.request.responseURL.replace(`/${this.ipfsHash}`, '');
        } else {
          // actual error
          console.error(err);
        }
      }
    },
  },
};
</script>

<style lang="scss">
.view-page {
  .v-card {
    max-width: 768px;

    .image-wrapper {
      background: #e0e0e0;

      border-top-left-radius: inherit;
      border-top-right-radius: inherit;

      overflow: hidden;

      img {
        display: block;

        max-width: 100%;
        margin: 0 auto;
      }
    }

  }
}
</style>
