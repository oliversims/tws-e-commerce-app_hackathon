"use client";

import React, {
  Dispatch,
  SetStateAction,
  Suspense,
  useEffect,
  useState,
  useCallback,
} from "react";
import { Input } from "./ui/input";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectLabel,
  SelectTrigger,
  SelectValue,
} from "./ui/select";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import Image from "next/image";
import { Button } from "./ui/button";
import { IoSearch } from "react-icons/io5";
import { cn } from "@/lib/utils";
import shops from "@/data/shops.json";
import { useToast } from "./ui/use-toast";

type SearchBarProps = {
  setIsSearchOpen?: Dispatch<SetStateAction<boolean>>;
  className?: string;
  useSelect?: boolean;
};

const SearchBarForm = ({
  setIsSearchOpen,
  className,
  useSelect,
}: SearchBarProps) => {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const { toast } = useToast();
  const [searchValue, setSearchValue] = useState("");
  const [selectedShop, setSelectedShop] = useState<undefined | string>(
    undefined
  );

  const shopFromPath = pathname.startsWith("/shops/")
    ? pathname.split("/")[2]
    : undefined;
  const activeShop =
    selectedShop && selectedShop !== "Select Shop"
      ? selectedShop
      : shops.find((shop) => shop.title === shopFromPath)?.title;

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!searchValue.trim()) return;

    if (!activeShop) {
      toast({
        title: "Select a shop",
        description: "Choose a shop first, then search for products.",
      });
      return;
    }

    router.push(`/shops/${activeShop}?q=${encodeURIComponent(searchValue.trim())}`);
    if (!setIsSearchOpen) return;
    setIsSearchOpen(false);
  };

  const handleSelectShop = useCallback((shop?: string) => {
    if (shop) {
      setSelectedShop(shop);
    }
  }, []);

  useEffect(() => {
    if (shopFromPath && shops.some((shop) => shop.title === shopFromPath)) {
      setSelectedShop(shopFromPath);
    }
  }, [shopFromPath]);

  return (
    <form
      className={cn(
        "searchBar flex items-center border-input border rounded-lg focus-within:border-primary overflow-hidden bg-secondary",
        className
      )}
      onSubmit={handleSubmit}
    >
      {useSelect && (
        <Select onValueChange={handleSelectShop} value={selectedShop}>
          <SelectTrigger className="min-w-[70px] max-w-fit border-none rounded-none bg-accent">
            <SelectValue placeholder="Select Shop" className="capitalize" />
          </SelectTrigger>
          <SelectContent>
            <SelectGroup>
              <SelectLabel className="text-muted-foreground">Shops</SelectLabel>
              {shops.map((shop, index) => (
                <SelectItem
                  value={shop.title}
                  key={index}
                  className="px-4 [&>.indicator]:hidden capitalize"
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
                </SelectItem>
              ))}
            </SelectGroup>
          </SelectContent>
        </Select>
      )}

      <Input
        placeholder="Search products"
        className="border-none rounded-none"
        type="text"
        onChange={(e) => setSearchValue(e.target.value)}
        defaultValue={searchParams.get("q")?.toString()}
      />

      <Button className="text-xl" type="submit">
        <IoSearch />
      </Button>
    </form>
  );
};

const SearchBar = ({
  setIsSearchOpen,
  className,
  useSelect = true,
}: SearchBarProps) => {
  return (
    <Suspense>
      <SearchBarForm
        setIsSearchOpen={setIsSearchOpen}
        className={className}
        useSelect={useSelect}
      />
    </Suspense>
  );
};

export default SearchBar;
