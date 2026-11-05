import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "FreightFlow AI", description: "Automatisation documentaire pour transitaires" };
export default function RootLayout({children}:{children:React.ReactNode}) {
 return <html lang="fr"><body>{children}</body></html>;
}
