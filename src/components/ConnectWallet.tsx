import { useEffect, useState } from "react";
import Web3Modal from "web3modal";
import WalletConnectProvider from "@walletconnect/web3-provider";
import { ethers } from "ethers";
import {
  Box,
  Button,
  Modal,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalFooter,
  ModalHeader,
  ModalOverlay,
  useDisclosure,
} from "@chakra-ui/react";
import { setProvider } from "../types";
import networkInfo from "../networkInfo";

const providerOptions = {
  walletconnect: {
    package: WalletConnectProvider, // required
    options: {
      infuraId: "055233e09a674ddf84b9653133f66836", // process.env.REACT_APP_INFURA_ID, // required
    },
  },
};
const web3Modal = new Web3Modal({
  network: "mainnet", // optional
  cacheProvider: false, // optional
  providerOptions, // required
});

export const targetNetwork = networkInfo.bsc_testnet;

const connectWallet = async (
  setLocalProvider: setProvider,
  openModal: any,
  setProviderIsFinal: any,
) => {
  try {
    const wc = await web3Modal.connect();
    const provider = new ethers.providers.Web3Provider(wc);

    const chainId = await (await provider.getNetwork()).chainId;
    if (chainId !== targetNetwork.chainId) {
      openModal();
      setLocalProvider(provider);
    } else {
      setLocalProvider(provider);
      setProviderIsFinal(true);
    }
  } catch (e) {
    console.log(`wc error: ${e}`);
  }
};

const ConnectWallet = ({
  setProvider,
  ...props
}:
  | {
    setProvider: setProvider;
  }
  | any) => {
  const { isOpen, onOpen, onClose } = useDisclosure();
  const [localProvider, setLocalProvider] = useState<any>();
  const [providerIsFinal, setProviderIsFinal] = useState(false);

  const switchNetwork = () => {
    const params = {
      chainId: ethers.utils.hexValue(targetNetwork.chainId),
    };

    localProvider
      .send("wallet_switchEthereumChain", [params])
      .then(async () => {
        // ethers providers are immutable so need to instantiate a new one
        setLocalProvider(
          new ethers.providers.Web3Provider(await web3Modal.connect()),
        );
        setProviderIsFinal(true);
      })
      .catch((error: any) => console.log(error));
  };

  useEffect(() => {
    if (providerIsFinal) {
      setProvider(localProvider);
    }
  }, [providerIsFinal]);

  return (
    <>
      <Button
        onClick={() =>
          connectWallet(setLocalProvider, onOpen, setProviderIsFinal)}
        {...props}
      >
        Connect Wallet
      </Button>
      <Modal isOpen={isOpen} onClose={onClose} isCentered>
        <ModalOverlay />
        <ModalContent>
          <ModalHeader>Incorrect Network</ModalHeader>
          <ModalCloseButton />
          <ModalBody>
            Press OK to switch to {targetNetwork.name} & use this DApp
          </ModalBody>

          <ModalFooter>
            <Button colorScheme="blue" mr={3} onClick={() => switchNetwork()}>
              OK
            </Button>
          </ModalFooter>
        </ModalContent>
      </Modal>
    </>
  );
};

export default ConnectWallet;
