import React, { useState, useEffect } from 'react';
import { Button, Flex, Grid, Slider, Text } from "@radix-ui/themes";

type ShareSelectorProps = {
  max: number;
  decimal: number;
  rate: number | null;
  symbol: string | null;
  onValueChange?: (value: number) => void;
};

export const ShareSelector: React.FC<ShareSelectorProps> = ({ max, decimal, rate, symbol, onValueChange }) => {
  const [share, setShare] = useState(0);
  const [inputValue, setInputValue] = useState('');

  const scaleValue = (value: number) => value / Math.pow(10, decimal) || 0;

  const handleSliderChange = (values: number[]) => {
    let value = values[0];
    setShare(value);
    const rawAbsolute = (value / 100) * max;
    const absolute = scaleValue((value / 100) * max);
    setInputValue(absolute.toFixed(3));
    onValueChange && onValueChange(Number(rawAbsolute.toFixed(0)));
  };

  const handleButtonClick = (value: number) => {
    setShare(value);
    const rawAbsolute = (value / 100) * max;
    const absolute = scaleValue((value / 100) * max);
    setInputValue(absolute.toFixed(3));
    onValueChange && onValueChange(Number(rawAbsolute.toFixed(0)));
  };

  
  let oldSelection: [string, number | null, number | null] | null = null;
  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (!/^\d*\.?\d*$/.test(event.target.value) && oldSelection) {
      console.log('invalid input')
      console.log(oldSelection)
      event.target.value = oldSelection[0];
      event.target.setSelectionRange(oldSelection[1], oldSelection[2]);
      return
    }
    const value = Number(event.target.value) * Math.pow(10, decimal);
    setInputValue(event.target.value);
    if (!isNaN(value)) {
      setShare(value / max * 100);
      onValueChange && onValueChange(value);
    }
  };

  const handleKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
    let t = event.target as HTMLInputElement;
    oldSelection = [t.value, t.selectionStart, t.selectionEnd];
  };

  const handleInputBlur = (event: React.FocusEvent<HTMLInputElement>) => {
    let value = Number(event.target.value) * Math.pow(10, decimal);
    if (value > max || isNaN(value) || value < 0) {
      if (value > max) {
        setInputValue(scaleValue(max).toFixed(3));
        value = max
      } else if (isNaN(value) || value < 0) {
        setInputValue("0");
        value = 0
      }
      setShare(value / max * 100);
      onValueChange && onValueChange(value);
    } else {
      const value = Number(event.target.value);
      setInputValue(value.toFixed(3));
    }
  };

  useEffect(() => {
    const absolute = scaleValue((share / 100) * max);
    setInputValue(absolute.toFixed(3));    
  }, [max, decimal]);

  return (
    <Flex direction="column" gap="2">
      <Slider value={[share]} onValueChange={handleSliderChange} min={0} max={100} />
      <Grid columns="5" gap="1">
      {[0, 25, 50, 75, 100].map(value => (
        <Button
          key={value}
          onClick={() => handleButtonClick(value)}
          variant={ share === value ? 'solid' : 'outline' }
          size="1"
          radius="small"
        >
          {value}%
        </Button>
      ))}
      </Grid>
      <input inputMode="decimal" value={inputValue} onChange={handleInputChange} onBlur={handleInputBlur} min={0} max={scaleValue(max)} onKeyDown={handleKeyDown} />
      {rate ? (<Text size="2">= {(Number(inputValue) * rate).toFixed(3)} {symbol}</Text>) : (<Text size="2">Loading...</Text>)}
    </Flex>
  );
};