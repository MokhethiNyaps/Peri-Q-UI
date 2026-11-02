import type { CSSProperties } from "react";

// Fixed positions (no randomness) so server and browser render the same sparks.
const EMBERS = [
  { left: "8%", delay: "0s", duration: "7.5s", drift: "24px" },
  { left: "17%", delay: "2.4s", duration: "8.5s", drift: "-18px" },
  { left: "29%", delay: "4.1s", duration: "6.8s", drift: "30px" },
  { left: "41%", delay: "1.2s", duration: "9s", drift: "-26px" },
  { left: "53%", delay: "5.3s", duration: "7.2s", drift: "16px" },
  { left: "64%", delay: "0.8s", duration: "8.2s", drift: "-30px" },
  { left: "72%", delay: "3.5s", duration: "6.5s", drift: "22px" },
  { left: "81%", delay: "6.1s", duration: "8.8s", drift: "-14px" },
  { left: "90%", delay: "2s", duration: "7.8s", drift: "20px" },
  { left: "96%", delay: "4.7s", duration: "9.4s", drift: "-22px" },
];

export function Embers() {
  return (
    <div className="embers" aria-hidden="true">
      {EMBERS.map((ember) => (
        <span
          key={ember.left}
          className="ember"
          style={
            {
              left: ember.left,
              "--ember-delay": ember.delay,
              "--ember-duration": ember.duration,
              "--ember-drift": ember.drift,
            } as CSSProperties
          }
        />
      ))}
    </div>
  );
}
