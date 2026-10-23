import nextVitals from "eslint-config-next/core-web-vitals";
import nextTypescript from "eslint-config-next/typescript";
import betterTailwindcss from "eslint-plugin-better-tailwindcss";

function explain(rule, advice) {
  return {
    ...rule,
    create(context) {
      const explained = Object.create(context, {
        report: { value: (report) => context.report({ ...report, message: `${report.message} ${advice}` }) },
      });
      return rule.create(explained);
    },
  };
}

// The Tailwind 4.1.14-compatible release calls unknown classes unregistered.
const tailwindPlugin = {
  ...betterTailwindcss,
  rules: {
    ...betterTailwindcss.rules,
    "no-unknown-classes": explain(betterTailwindcss.rules["no-unregistered-classes"],
      "Use a Tailwind utility or a design colour defined in src/app/globals.css."),
    "no-conflicting-classes": explain(betterTailwindcss.rules["no-conflicting-classes"],
      "Use one utility for each property and remove the conflicting class."),
  },
};

const config = [
  ...nextVitals,
  ...nextTypescript,
  { ignores: [".next/**", "node_modules/**", "next-env.d.ts", ".agents/**", ".claude/**"] },
  {
    files: ["src/**/*.{js,jsx,ts,tsx}"],
    plugins: { "better-tailwindcss": tailwindPlugin },
    settings: { "better-tailwindcss": { entryPoint: "src/app/globals.css" } },
    rules: {
      "better-tailwindcss/no-unknown-classes": "error",
      "better-tailwindcss/no-conflicting-classes": "error",
    },
  },
  {
    files: ["src/components/ui/sonner.tsx"],
    rules: {
      // Sonner uses this class as its own selector.
      "better-tailwindcss/no-unknown-classes": ["error", { ignore: ["^toaster$"] }],
    },
  },
  {
    files: ["src/**/*.{js,jsx,ts,tsx}"],
    ignores: ["src/components/ui/**"],
    rules: {
      "better-tailwindcss/no-restricted-classes": ["error", {
        restrict: [
          {
            pattern: "(?:^|:)!?(?:bg|text|border(?:-[trblxyse])?|ring(?:-offset)?|outline|shadow|decoration|divide|accent|caret|fill|stroke|from|via|to)-(?:slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-[0-9]+(?:/.*)?!?$",
            message: "Use a design colour such as bg-primary or text-muted-foreground. Add a named colour in src/app/globals.css if needed.",
          },
          {
            pattern: "(?:^|:)!?(?:bg|text|border(?:-[trblxyse])?|ring(?:-offset)?|outline|shadow|decoration|divide|accent|caret|fill|stroke|from|via|to)-(?:black|white)(?:/.*)?!?$|(?:^|:)!?(?:bg|text|border(?:-[trblxyse])?|ring(?:-offset)?|outline|shadow|decoration|divide|accent|caret|fill|stroke|from|via|to)-\\[(?:#|(?:rgba?|hsla?|hwb|(?:ok)?lab|(?:ok)?lch|color(?:-mix)?|light-dark|var)\\(|color:|[a-zA-Z]+\\])|(?:^|:)!?\\[(?:color|background(?:-color)?|border(?:-[a-z]+)?|outline(?:-color)?|fill|stroke|caret-color|accent-color):",
            message: "Use a named design colour from src/app/globals.css instead of a literal or arbitrary colour.",
          },
        ],
      }],
      "no-restricted-syntax": ["error",
        {
          selector: "JSXOpeningElement[name.type='JSXIdentifier'][name.name=/^(button|input|select|textarea)$/]",
          message: "Use a component from src/components/ui/. Add one with npx shadcn add <name>.",
        },
        {
          selector: "JSXAttribute[name.name='style'] :matches(Property[key.name=/^(color|background|backgroundColor|border.*|outline.*|fill|stroke|caretColor|accentColor|boxShadow|textShadow|textDecorationColor|columnRuleColor)$/], Property[key.value=/^(color|background|background-color|border.*|outline.*|fill|stroke|caret-color|accent-color|box-shadow|text-shadow|text-decoration-color|column-rule-color|--.*)$/])",
          message: "Use design colour classes instead of inline styles. Add a named colour in src/app/globals.css if needed.",
        },
      ],
    },
  },
];

export default config;
