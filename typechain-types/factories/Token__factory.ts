/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../common";
import type { Token, TokenInterface } from "../Token";

const _abi = [
  {
    inputs: [],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "_from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "_to",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "_value",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_account",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "symbol",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalSupply",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "_amount",
        type: "uint256",
      },
    ],
    name: "transfer",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60c0604052601060808190526f26bc902430b9323430ba102a37b5b2b760811b60a0908152610031916000919061009e565b5060408051808201909152600280825261121560f21b602090920191825261005b9160019161009e565b50620186a060025534801561006f57600080fd5b5060025433600081815260046020526040902091909155600380546001600160a01b0319169091179055610172565b8280546100aa90610137565b90600052602060002090601f0160209004810192826100cc5760008555610112565b82601f106100e557805160ff1916838001178555610112565b82800160010185558215610112579182015b828111156101125782518255916020019190600101906100f7565b5061011e929150610122565b5090565b5b8082111561011e5760008155600101610123565b600181811c9082168061014b57607f821691505b6020821081141561016c57634e487b7160e01b600052602260045260246000fd5b50919050565b610406806101816000396000f3fe608060405234801561001057600080fd5b50600436106100625760003560e01c806306fdde031461006757806318160ddd1461008557806370a082311461009c5780638da5cb5b146100c557806395d89b41146100f0578063a9059cbb146100f8575b600080fd5b61006f61010d565b60405161007c9190610293565b60405180910390f35b61008e60025481565b60405190815260200161007c565b61008e6100aa366004610304565b6001600160a01b031660009081526004602052604090205490565b6003546100d8906001600160a01b031681565b6040516001600160a01b03909116815260200161007c565b61006f61019b565b61010b610106366004610326565b6101a8565b005b6000805461011a90610350565b80601f016020809104026020016040519081016040528092919081815260200182805461014690610350565b80156101935780601f1061016857610100808354040283529160200191610193565b820191906000526020600020905b81548152906001019060200180831161017657829003601f168201915b505050505081565b6001805461011a90610350565b336000908152600460205260409020548111156101fe5760405162461bcd60e51b815260206004820152601060248201526f2737ba1032b737bab3b4103a37b5b2b760811b604482015260640160405180910390fd5b336000908152600460205260408120805483929061021d9084906103a1565b90915550506001600160a01b0382166000908152600460205260408120805483929061024a9084906103b8565b90915550506040518181526001600160a01b0383169033907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9060200160405180910390a35050565b600060208083528351808285015260005b818110156102c0578581018301518582016040015282016102a4565b818111156102d2576000604083870101525b50601f01601f1916929092016040019392505050565b80356001600160a01b03811681146102ff57600080fd5b919050565b60006020828403121561031657600080fd5b61031f826102e8565b9392505050565b6000806040838503121561033957600080fd5b610342836102e8565b946020939093013593505050565b600181811c9082168061036457607f821691505b6020821081141561038557634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052601160045260246000fd5b6000828210156103b3576103b361038b565b500390565b600082198211156103cb576103cb61038b565b50019056fea26469706673582212206f0629dd011708a0618317f3fcd735c4937c538d8d3646411222857a813fbfb364736f6c63430008090033";

type TokenConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: TokenConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class Token__factory extends ContractFactory {
  constructor(...args: TokenConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<Token> {
    return super.deploy(overrides || {}) as Promise<Token>;
  }
  override getDeployTransaction(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  override attach(address: string): Token {
    return super.attach(address) as Token;
  }
  override connect(signer: Signer): Token__factory {
    return super.connect(signer) as Token__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): TokenInterface {
    return new utils.Interface(_abi) as TokenInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): Token {
    return new Contract(address, _abi, signerOrProvider) as Token;
  }
}
