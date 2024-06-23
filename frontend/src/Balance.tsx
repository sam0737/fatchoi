import { useCurrentAccount, useSuiClientQueries } from "@mysten/dapp-kit";
import { CoinMetadata } from "@mysten/sui/client";
import { Flex, Text } from "@radix-ui/themes";

type BalanceProps = {
  data: {
    totalBalance: Number | undefined;
    metadata: CoinMetadata | null | undefined;
  };
  error: Error | null | undefined;
}

export function getBalance(type: string) {
  const account = useCurrentAccount();
  const { data, isSuccess, isPending, error } = useSuiClientQueries({
    queries: [
      {
        method: "getBalance",
        params: {
          owner: account?.address as string,
          coinType: type,
        }
      },
      {
        method: "getCoinMetadata",
        params: {
          coinType: type,
        }
      },
    ],    
		combine: (result) => {
			return {
				data: { totalBalance: Number(result[0].data?.totalBalance), metadata: result[1].data },
				isSuccess: result.every((res) => res.isSuccess),
				isPending: result.some((res) => res.isPending),        
				error: result.find(item => item.error)?.error,
			};
		},
  });
  return { data, isSuccess, isPending, error }
}

export function Balance(props : BalanceProps) {
  const { data, error } = props;

  if (error) {
    return <Flex>Error: {error.message}</Flex>;
  }

  if (!data || data.totalBalance == null) {
    return <Flex>Loading...</Flex>;
  }

  let decimals = Number(data.metadata?.decimals || 0)
  return (
    <Flex direction="column">
      <Text>{ data.metadata?.symbol }</Text>
      <Text size="7" weight="bold">{ (Number(data.totalBalance) / Math.pow(10, decimals)).toFixed(3) }</Text>
    </Flex>
  );
}
