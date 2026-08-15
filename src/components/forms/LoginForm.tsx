"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import { z } from "zod";

import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import {
  User,
  setAuthenticated,
  setCurrentUser,
} from "@/lib/features/auth/authSlice";
import { safeRedirectPath } from "@/lib/auth/safeRedirect";
import fetchData from "@/lib/fetchDataFromApi";
import { useAppSelector } from "@/lib/hooks";
import { useRouter, useSearchParams } from "next/navigation";
import { Dispatch, SetStateAction, useState } from "react";
import { FcGoogle } from "react-icons/fc";
import { LuLoader } from "react-icons/lu";
import { useDispatch } from "react-redux";
import { useToast } from "../ui/use-toast";

const formSchema = z.object({
  email: z.string().email("Invalid email address"),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

type LoginFormProps = {
  setIsOpen?: Dispatch<SetStateAction<boolean>>;
};

export function LoginForm({ setIsOpen }: LoginFormProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { toast } = useToast();
  const [isLoading, setIsLoading] = useState(false);
  const { cartItems } = useAppSelector((state) => state.cartSlice);
  const dispatch = useDispatch();

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      email: "",
      password: "",
    },
  });

  async function onSubmit(values: z.infer<typeof formSchema>) {
    setIsLoading(true);

    try {
      // The session cookie is set by the API response itself. There is
      // deliberately no follow-up call to write it client-side -- doing so
      // replaced the httpOnly cookie with a script-readable one.
      const res = await fetchData.post("/auth/login", values);

      dispatch(setCurrentUser(res.data.user as User));
      dispatch(setAuthenticated(true));
      form.reset();
      setIsOpen && setIsOpen(false);

      toast({
        title: "Success",
        description: "You have successfully Logged in",
        variant: "success",
      });

      const redirectTo = safeRedirectPath(searchParams.get("redirect"));

      if (redirectTo === "/checkout" && cartItems.length === 0) {
        router.replace("/");
        toast({
          title: "Empty Cart",
          description: "Please add items to your cart before checking out",
          variant: "default",
        });
      } else {
        router.replace(redirectTo);
      }

      router.refresh();
    } catch (error: any) {
      toast({
        title: "Authentication failed",
        description: error.response?.data?.error || "Please try again",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <Form {...form}>
      <form
        onSubmit={form.handleSubmit(onSubmit)}
        className="flex flex-col gap-3"
      >
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input
                  type="email"
                  autoComplete="email"
                  placeholder="Enter your email"
                  {...field}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormField
          control={form.control}
          name="password"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Password</FormLabel>
              <FormControl>
                <Input
                  type="password"
                  autoComplete="current-password"
                  placeholder="Enter your password"
                  {...field}
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button
          type="submit"
          className="w-full mt-2"
          disabled={isLoading}
        >
          {isLoading ? (
            <span className="flex items-center gap-2">
              <LuLoader className="animate-spin" /> Please wait...
            </span>
          ) : (
            "Login"
          )}
        </Button>

        <Button
          type="button"
          variant="outline"
          className="w-full flex items-center gap-2"
          onClick={() =>
            toast({
              title: "Google login unavailable",
              description: "Use email and password to sign in.",
            })
          }
        >
          <FcGoogle className="text-xl" />
          Login with Google
        </Button>
      </form>
    </Form>
  );
}
