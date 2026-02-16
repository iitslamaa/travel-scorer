export function getScoreColor(score: number) {
  if (score >= 85) {
    return {
      background: "#DDF5E6",
      text: "#0E6B3E",
    };
  }

  if (score >= 70) {
    return {
      background: "#F8F1C6",
      text: "#8B6B00",
    };
  }

  return {
    background: "#FAD4D4",
    text: "#8A1C1C",
  };
}