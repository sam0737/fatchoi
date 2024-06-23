import { useState } from 'react';
import * as Toast from '@radix-ui/react-toast';
import { useCurrentAccount, useSignAndExecuteTransaction } from "@mysten/dapp-kit";
import { Container, Box, Button, Grid, Flex, Heading, Text, Separator } from "@radix-ui/themes";
import { getBalance, Balance } from "../Balance";
import { ShareSelector } from "../ShareSelector";
import { Transaction, coinWithBalance } from '@mysten/sui/transactions';

import Constant, { GetData } from './BucketV1';
import { SUI_CLOCK_OBJECT_ID } from '@mysten/sui/utils';
import '../styles.css'

type TransactionResult =
  | { key?: string, success: string; error?: never }
  | { key?: string, error: string; success?: never };

export default function WalletStatus() {
  let { rates, tvl } = GetData()

  const account = useCurrentAccount();
  const { mutate: signAndExecuteTransaction } = useSignAndExecuteTransaction();

  const buckBalance = getBalance(Constant.coin.BUCK);
  const fcBalance = getBalance(Constant.coin.token);

  const [buckSelected, setBuckSelected] = useState(0);
  const [fcSelected, setFcSelected] = useState(0);

  const handleBuckSelection = (value: number) => {
    setBuckSelected(value)
  }
  const handleFcSelection = (value: number) => {
    setFcSelected(value)
  }

  const [data, setData] = useState<TransactionResult[]>([]);
  const addResult = (result: TransactionResult) => {
    result.key = (Math.random() + 1).toString(36).substring(7);
    setData(p => [...p, result]);
  }

  const handleDeposit = () => {
    const tx = new Transaction()
    tx.setSender(account?.address as string)
    tx.moveCall({
      package: Constant.package,
      module: Constant.module,
      function: "deposit_entry",
      typeArguments: [Constant.coin.token],
      arguments: [
        tx.object(Constant.vault),
        tx.object(SUI_CLOCK_OBJECT_ID),
        tx.object(Constant.flask),
        tx.object(Constant.fountain),
        coinWithBalance({ type: Constant.coin.BUCK, balance: buckSelected }),
      ]
    })

    signAndExecuteTransaction(
      { transaction: tx },
      {
        onError: (error) => {
          addResult({ error: error.message })
        },
        onSuccess: (result) => {
          addResult({ success: result.digest })
        }
      }
    )
  }

  const handleWithdraw = () => {
    const tx = new Transaction()
    tx.setSender(account?.address as string)
    tx.moveCall({
      package: Constant.package,
      module: Constant.module,
      function: "withdraw_entry",
      typeArguments: [Constant.coin.token],
      arguments: [
        tx.object(Constant.vault),
        tx.object(SUI_CLOCK_OBJECT_ID),
        tx.object(Constant.flask),
        tx.object(Constant.fountain),
        coinWithBalance({ type: Constant.coin.token, balance: fcSelected }),
      ]
    })

    signAndExecuteTransaction(
      { transaction: tx },
      {
        onError: (error) => {
          addResult({ error: error.message })
        },
        onSuccess: (result) => {
          addResult({ success: result.digest })
        }
      }
    )
  }

  return (
    <Container my="2">
      <Heading>BUCK Staking</Heading>
      <Heading size="4">TVL: ${tvl?.toFixed(2)} USDC</Heading>
      {account ? (
        <Box>
          <Toast.Provider swipeDirection="right">
            {data.map((item) => (
              <Toast.Root className="ToastRoot" duration={15000} key={item.key}
                onOpenChange={open => {
                  if (!open) {
                    setData(prevData => prevData.filter((x, _) => x.key !== item.key));
                  }
                  console.log(data)
                }}>
                <div className="ToastBox">
                  <Toast.Title className="ToastTitle">Transaction Result</Toast.Title>
                  <Toast.Description asChild>
                    <div className="ToastDescription">
                      {item.error ? (
                        <p>{item.error}</p>
                      ) : (
                        <p>Transaction <a href={`https://suiscan.xyz/mainnet/tx/${item.success}`}>{item.success}</a> submitted</p>
                      )}
                    </div>
                  </Toast.Description>
                </div>
                <div className={`progressBar ${item.success ? 'success' : 'error'}`} />
              </Toast.Root>
            ))}
            <Toast.Viewport className="ToastViewport">
            </Toast.Viewport>
          </Toast.Provider>
          <Grid columns="100fr 100fr" m="4">
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
              <Flex direction="column">
                <Flex direction="column" align="center">
                  <Balance data={buckBalance.data} error={buckBalance.error} />
                  <Separator size="4" my="4" />
                  <Text size="6" mb="2">
                    Deposit
                  </Text>
                  <ShareSelector max={buckBalance.data?.totalBalance ?? 0} decimal={buckBalance.data.metadata?.decimals ?? 0}
                    rate={rates ? 1 / rates["SBUCK_BUCK"] / rates["fcBUCKv1_SBUCK"] : null}
                    symbol="fcBUCKv1"
                    onValueChange={handleBuckSelection} />
                </Flex>
                <Button my="2" color="green" onClick={handleDeposit} disabled={buckSelected == 0}>
                  Deposit
                </Button>
              </Flex>
            </div>
            <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
              <Flex direction="column">
                <Flex direction="column" align="center">
                  <Balance data={fcBalance.data} error={fcBalance.error} />
                  <Separator size="4" my="4" />
                  <Text size="6" mb="2">
                    Withdraw
                  </Text>
                  <ShareSelector max={(fcBalance.data?.totalBalance ?? 0)} decimal={fcBalance.data.metadata?.decimals ?? 0}
                    rate={rates ? rates["SBUCK_BUCK"] * rates["fcBUCKv1_SBUCK"] : null}
                    symbol="BUCK"
                    onValueChange={handleFcSelection} />
                </Flex>
                <Button my="2" color="red" onClick={handleWithdraw} disabled={fcSelected == 0}>
                  Withdraw
                </Button>
              </Flex>
            </div>
          </Grid>
        </Box>
      ) : (
        <Box py="2">Wallet not connected</Box>
      )}
    </Container>
  );
}
