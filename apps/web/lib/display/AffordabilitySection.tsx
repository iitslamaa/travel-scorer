import type { CountryFacts } from "@/lib/facts";

type Props = {
  facts?: CountryFacts;
  tripLengthDays?: number; // future use when we wire dates
};

function describeCostBucket(category?: number): string | null {
  if (category == null || !Number.isFinite(category)) return null;
  if (category <= 2) return "very cheap compared with other countries";
  if (category <= 4) return "on the cheaper side overall";
  if (category <= 7) return "moderate compared with other countries";
  if (category <= 9) return "on the expensive side overall";
  return "among the most expensive destinations";
}

export function AffordabilitySection({ facts, tripLengthDays }: Props) {
  if (!facts) return null;

  const fx = facts as unknown as {
    affordability?: number;           // 0–100, cheap = 100
    affordabilityCategory?: number;   // 1 = cheapest, 10 = most expensive
    averageDailyCostUsd?: number;
    dailySpend?: {
      totalUsd?: number;
      hotelUsd?: number;
      hostelUsd?: number;
      foodUsd?: number;
      transportUsd?: number;
    };
  };

  const category = fx.affordabilityCategory;
  const score100 = fx.affordability;
  const averageDailyCost = fx.averageDailyCostUsd;
  const spend = fx.dailySpend || {};

  const bucketDescription = describeCostBucket(category);

  const hasAnyBreakdown =
    spend.hotelUsd != null ||
    spend.hostelUsd != null ||
    spend.foodUsd != null ||
    spend.transportUsd != null;

  const totalTripCost =
    tripLengthDays && Number.isFinite(averageDailyCost || NaN)
      ? (averageDailyCost as number) * tripLengthDays
      : null;

  if (category == null && averageDailyCost == null && !hasAnyBreakdown) {
    // nothing to show
    return null;
  }

  return (
    <section className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold">Affordability</h2>

        {typeof score100 === "number" && (
          <div className="inline-flex items-center rounded-full border px-3 py-1 text-xs">
            <span className="mr-1 text-muted-foreground">Affordability</span>
            <span className="font-semibold">{score100}</span>
          </div>
        )}
      </div>

      <p className="text-sm text-muted-foreground">
        {typeof category === "number" && (
          <>
            Cost level:{" "}
            <span className="font-medium">
              {category}/10{" "}
              {category === 1
                ? "(cheapest)"
                : category === 10
                ? "(most expensive)"
                : ""}
            </span>
            {bucketDescription && (
              <>
                {" "}
                <span className="text-xs text-muted-foreground">
                  – {bucketDescription}.
                </span>
              </>
            )}
          </>
        )}

        {Number.isFinite(averageDailyCost || NaN) && (
          <>
            {category != null && " · "}
            Typical daily spend around{" "}
            <span className="font-medium">
              ${Math.round(averageDailyCost as number)}
            </span>{" "}
            per person
          </>
        )}

        {totalTripCost && (
          <>
            <br />
            <span className="text-xs">
              For a {tripLengthDays}-day trip, roughly $
              {Math.round(totalTripCost)} per person.
            </span>
          </>
        )}
      </p>

      {hasAnyBreakdown && (
        <div className="grid grid-cols-2 gap-3 text-sm">
          {spend.hotelUsd != null && (
            <div>
              <div className="text-xs uppercase text-muted-foreground">
                Hotel (night)
              </div>
              <div className="font-medium">
                ${Math.round(spend.hotelUsd)}
              </div>
            </div>
          )}

          {spend.hostelUsd != null && (
            <div>
              <div className="text-xs uppercase text-muted-foreground">
                Hostel (night)
              </div>
              <div className="font-medium">
                ${Math.round(spend.hostelUsd)}
              </div>
            </div>
          )}

          {spend.foodUsd != null && (
            <div>
              <div className="text-xs uppercase text-muted-foreground">
                Food (day)
              </div>
              <div className="font-medium">
                ${Math.round(spend.foodUsd)}
              </div>
            </div>
          )}

          {spend.transportUsd != null && (
            <div>
              <div className="text-xs uppercase text-muted-foreground">
                Transport (day)
              </div>
              <div className="font-medium">
                ${Math.round(spend.transportUsd)}
              </div>
            </div>
          )}
        </div>
      )}
    </section>
  );
}