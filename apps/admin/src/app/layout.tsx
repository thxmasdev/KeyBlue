import type { Metadata } from 'next';
import './globals.css';
import { Sidebar } from '@/components/Sidebar';

export const metadata: Metadata = {
  title: 'KeyBlue - Teclado Android Inteligente',
  description: 'Teclado nativo Android de alto rendimiento con motor T9 y distribuciones completas.',
  icons: {
    icon: '/favicon.png',
    apple: '/keyblue_logo.png',
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <body className="flex flex-col md:flex-row min-h-screen bg-[#0A0D14]">
        <Sidebar />
        <main className="flex-1 min-w-0 overflow-y-auto">{children}</main>
      </body>
    </html>
  );
}

