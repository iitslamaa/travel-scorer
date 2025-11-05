export type Country = {
  code: string;
  name: string;
  usStateDeptLevel: 1|2|3|4;
  englishIndex: number;       // 0-100
  affordability: number;      // 0-100 (higher = cheaper)
  bestMonths: number[];       // 1..12
  visaUS: 'visa-free' | 'evisa' | 'visa-required';
  estFlightHrsFromNYC: number;
  transit: 'great-pt'|'car-needed'|'mixed';
  womenSafety: number;        // 0-100
  soloSafety: number;         // 0-100
  cardsAcceptance: 'wide'|'limited'|'cash-heavy';
  applePay: boolean;
  tags: string[];
};

export const COUNTRIES: Country[] = [
  { code:'IS', name:'Iceland', usStateDeptLevel:1, englishIndex:90, affordability:45, bestMonths:[2,3,9,10],
    visaUS:'visa-free', estFlightHrsFromNYC:5.5, transit:'mixed', womenSafety:85, soloSafety:88,
    cardsAcceptance:'wide', applePay:true, tags:['nature','activities'] },
  { code:'TH', name:'Thailand', usStateDeptLevel:2, englishIndex:57, affordability:80, bestMonths:[11,12,1,2,3],
    visaUS:'visa-free', estFlightHrsFromNYC:20, transit:'mixed', womenSafety:60, soloSafety:70,
    cardsAcceptance:'limited', applePay:false, tags:['food','activities','nature'] },
  { code:'GB', name:'United Kingdom', usStateDeptLevel:2, englishIndex:100, affordability:55, bestMonths:[5,6,9],
    visaUS:'visa-free', estFlightHrsFromNYC:7, transit:'great-pt', womenSafety:72, soloSafety:78,
    cardsAcceptance:'wide', applePay:true, tags:['history','architecture','food'] },
  { code:'JP', name:'Japan', usStateDeptLevel:1, englishIndex:55, affordability:60, bestMonths:[3,4,10,11],
    visaUS:'visa-free', estFlightHrsFromNYC:14, transit:'great-pt', womenSafety:90, soloSafety:92,
    cardsAcceptance:'wide', applePay:true, tags:['food','architecture','activities','history'] },
  { code:'MA', name:'Morocco', usStateDeptLevel:2, englishIndex:35, affordability:72, bestMonths:[4,5,9,10],
    visaUS:'visa-free', estFlightHrsFromNYC:7, transit:'mixed', womenSafety:55, soloSafety:62,
    cardsAcceptance:'limited', applePay:false, tags:['architecture','history','food','nature'] },
];