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
import { Textarea } from "../ui/textarea";
import { Variants, motion } from "framer-motion";
import { useEffect } from "react";
import { addressSchema } from "@/lib/validation/schemas";

export type AddressFormValues = z.infer<typeof addressSchema>;

const emptyAddress: AddressFormValues = {
  title: "",
  phone: "",
  streetAddress: "",
  city: "",
  state: "",
  country: "",
  zip: "",
};

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 50 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      type: "tween",
    },
  },
  exit: { opacity: 0, y: 50 },
};

type AddressFormProps = {
  /** "billing" | "shipping" -- drives the heading and the data attribute. */
  kind: "billing" | "shipping";
  heading: string;
  onFormDataChange: (data: AddressFormValues) => void;
};

/**
 * Shared by the billing and shipping steps. These were two near-identical files
 * whose "identical" default values had already drifted apart.
 */
const AddressForm = ({ kind, heading, onFormDataChange }: AddressFormProps) => {
  const form = useForm<AddressFormValues>({
    resolver: zodResolver(addressSchema),
    defaultValues: emptyAddress,
    mode: "onBlur",
  });

  const { watch, getValues } = form;

  // Subscribes through react-hook-form rather than relying on the DOM change
  // event bubbling out of <form>, which misses programmatic updates and
  // non-bubbling controls.
  useEffect(() => {
    onFormDataChange(getValues());

    const subscription = watch((values) => {
      onFormDataChange(values as AddressFormValues);
    });

    return () => subscription.unsubscribe();
  }, [watch, getValues, onFormDataChange]);

  function onSubmit(values: AddressFormValues) {
    onFormDataChange(values);
  }

  return (
    <div className={`${kind}-form`} data-form-type={kind}>
      <h1 className="text-xl font-medium mb-4">{heading}</h1>
      <Form {...form}>
        <form className="space-y-4" onSubmit={form.handleSubmit(onSubmit)}>
          <div className="flex gap-4 items-center flex-col md:flex-row w-full">
            <motion.div variants={itemVariants} className="w-full md:w-1/2">
              <FormField
                control={form.control}
                name="title"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Full Name</FormLabel>
                    <FormControl>
                      <Input placeholder="Enter your full name" autoComplete="name" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </motion.div>

            <motion.div variants={itemVariants} className="w-full md:w-1/2">
              <FormField
                control={form.control}
                name="phone"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Phone</FormLabel>
                    <FormControl>
                      <Input placeholder="+88017*********" autoComplete="tel" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </motion.div>
          </div>

          <div className="flex gap-4 items-center flex-col md:flex-row w-full">
            <motion.div variants={itemVariants} className="w-full md:w-1/2">
              <FormField
                control={form.control}
                name="country"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Country</FormLabel>
                    <FormControl>
                      <Input placeholder="Enter your country" autoComplete="country-name" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </motion.div>
            <motion.div variants={itemVariants} className="w-full md:w-1/2">
              <FormField
                control={form.control}
                name="city"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>City</FormLabel>
                    <FormControl>
                      <Input placeholder="City" autoComplete="address-level2" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </motion.div>
          </div>

          <div className="flex gap-4 items-center flex-col md:flex-row w-full">
            <motion.div variants={itemVariants} className="w-full md:w-1/2">
              <FormField
                control={form.control}
                name="state"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>State</FormLabel>
                    <FormControl>
                      <Input placeholder="State" autoComplete="address-level1" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </motion.div>

            <motion.div variants={itemVariants} className="w-full md:w-1/2">
              <FormField
                control={form.control}
                name="zip"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>ZIP</FormLabel>
                    <FormControl>
                      <Input placeholder="eg: 1400" autoComplete="postal-code" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </motion.div>
          </div>

          <motion.div variants={itemVariants}>
            <FormField
              control={form.control}
              name="streetAddress"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Street Address</FormLabel>
                  <FormControl>
                    <Textarea
                      placeholder="eg: 2148 Straford Park"
                      id={`${kind}-streetAddress`}
                      autoComplete="street-address"
                      {...field}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
          </motion.div>
          <div className="flex justify-end">
            <Button type="submit">Save</Button>
          </div>
        </form>
      </Form>
    </div>
  );
};

export default AddressForm;
