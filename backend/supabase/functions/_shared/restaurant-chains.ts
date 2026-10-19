// Generated from shared/restaurant-chains.json. Do not edit the aliases here.
const aliases = [
  "burger king",
  "burgerking",
  "chicken treat",
  "dominos",
  "grilld",
  "guzman y gomez",
  "hungry jacks",
  "hungryjacks",
  "kentucky fried chicken",
  "kfc",
  "mcdonald",
  "mcdonalds",
  "nandos",
  "oporto",
  "pizza hut",
  "red rooster",
  "starbucks",
  "subway",
  "taco bell",
  "the coffee club",
  "zambrero",
];

export function isChainRestaurant(name: string): boolean {
  const normalised = name.toLowerCase().replace(/['’‘ʼ`]/g, "").replace(/[^a-z0-9]+/g, " ").trim();
  return aliases.some((alias) => ` ${normalised} `.includes(` ${alias} `));
}
