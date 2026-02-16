export type Country = {
  iso2: string;
  name: string;
  facts: {
    scoreTotal: number;
    advisoryLevel?: number;
    [key: string]: any;
  };
  [key: string]: any;
};