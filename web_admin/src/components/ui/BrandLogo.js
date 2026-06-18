"use client";

export default function BrandLogo({ className = "h-10 w-auto", alt = "RutaSegura" }) {
  return (
    <picture>
      <source srcSet="/images/logo.png" type="image/png" />
      <img src="/images/logo.svg" alt={alt} className={className} />
    </picture>
  );
}