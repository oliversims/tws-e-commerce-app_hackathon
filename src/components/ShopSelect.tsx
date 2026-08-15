"use client";

import { usePathname, useRouter } from "next/navigation";
import React, { useEffect, useState } from "react";
import { IoIosArrowDown } from "react-icons/io";
import Image from "next/image";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuTrigger,
} from "./ui/dropdown-menu";
import shops from "@/data/shops.json";

type ShopOption = {
  title: string;
  icon: string;
};

const placeholderShop: ShopOption = {
  title: "Select Shop",
  icon: "",
};

const ShopSelect = () => {
  const router = useRouter();
  const pathname = usePathname();
  const shopSlug = pathname.split("/")[2];
  const shopFromPath = shops.find((shop) => shop.title === shopSlug);
  const [selectedShop, setSelectedShop] = useState<ShopOption>(
    shopFromPath || placeholderShop
  );

  useEffect(() => {
    setSelectedShop(shopFromPath || placeholderShop);
  }, [shopSlug, shopFromPath]);

  const handleSelectShop = (shop: string) => {
    const foundShop = shops.find((s) => s.title === shop);
    if (!foundShop) return;
    setSelectedShop(foundShop);
    router.push(`/shops/${shop}`);
  };

  return (
    <DropdownMenu modal={false}>
      <DropdownMenuTrigger className="min-w-[70px] max-w-fit bg-accent pl-2 pr-3 rounded-lg border">
        <div className="flex items-center capitalize min-h-10">
          {selectedShop.icon && (
            <Image
              src={selectedShop.icon}
              width={40}
              height={40}
              alt={selectedShop.title}
            />
          )}

          <span>{selectedShop.title}</span>
          <span className="inline-block pl-1">
            <IoIosArrowDown />
          </span>
        </div>
      </DropdownMenuTrigger>
      <DropdownMenuContent
        align="end"
        className="max-h-[60vh] overflow-auto narrowScrollbar"
      >
        <DropdownMenuGroup>
          <DropdownMenuLabel className="text-muted-foreground px-4">
            Shops
          </DropdownMenuLabel>
          {shops.map((shop, index) => (
            <DropdownMenuItem
              key={index}
              className="px-4 [&>.indicator]:hidden capitalize"
              onClick={() => handleSelectShop(shop.title)}
            >
              <div className="flex items-center">
                <Image
                  src={shop.icon}
                  width={40}
                  height={40}
                  alt={shop.title}
                />

                <span>{shop.title}</span>
              </div>
            </DropdownMenuItem>
          ))}
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
};

export default ShopSelect;
