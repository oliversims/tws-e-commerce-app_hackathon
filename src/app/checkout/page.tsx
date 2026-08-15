"use client";

import HistoryBackBtn from "@/components/HistoryBackBtn";
import OrderSummery from "@/components/checkout/OrderSummery";
import BillingAddressForm from "@/components/forms/BillingAddressForm";
import ShippingAddressForm from "@/components/forms/ShippingAddressForm";
import { AnimatePresence, Variants, motion } from "framer-motion";
import { useCallback, useState } from "react";

const containerVariants: Variants = {
  hidden: {
    opacity: 0,
  },
  visible: {
    opacity: 1,
    transition: {
      when: "beforeChildren",
      staggerChildren: 0.1,
    },
  },

  exit: {
    opacity: 0,
    transition: {
      when: "afterChildren",
    },
  },
};

const btns = [
  {
    title: "billing",
  },
  {
    title: "shipping",
  },
];

// Addresses start empty. They previously defaulted to a real person's name and
// street address, so any customer who never opened the form placed an order
// shipped to it.
const emptyAddress = {
  title: "",
  phone: "",
  country: "",
  city: "",
  state: "",
  zip: "",
  streetAddress: "",
};

const CheckoutPage = () => {
  const [activeForm, setActiveForm] = useState("billing");
  const [formData, setFormData] = useState<{
    shipping: any;
    billing: any;
  }>({ shipping: emptyAddress, billing: emptyAddress });

  // Stable identity so the child forms' effects do not re-fire on every render
  // of this page.
  const updateFormData = useCallback((type: 'shipping' | 'billing', data: any) => {
    setFormData(prev => ({
      ...prev,
      [type]: data
    }));
  }, []);

  const handleBillingChange = useCallback(
    (data: any) => updateFormData('billing', data),
    [updateFormData]
  );

  const handleShippingChange = useCallback(
    (data: any) => updateFormData('shipping', data),
    [updateFormData]
  );

  return (
    <div className="checkout-page">
      <div className="container pt-7 pb-20">
        <HistoryBackBtn />
        <div className="flex gap-7 flex-col pt-7 md:flex-row">
          <AnimatePresence mode="wait">
            <div className="left w-full md:w-3/5 bg-secondary shadow-lg py-10 px-5 rounded-lg overflow-hidden h-fit">
              <h2 className="text-2xl font-bold mb-5">Checkout</h2>
              <div className="flex gap-5 mb-5">
                {btns.map((btn) => (
                  <button
                    type="button"
                    key={btn.title}
                    className={`${
                      activeForm === btn.title
                        ? "text-white"
                        : "text-foreground"
                    } px-5 py-2 bg-accent rounded-lg border capitalize relative`}
                    onClick={() => setActiveForm(btn.title)}
                  >
                    <span className="relative z-10">{btn.title}</span>
                    {activeForm === btn.title && (
                      <motion.span
                        layout
                        layoutId="active"
                        transition={{ type: "spring" }}
                        className="absolute top-0 left-0 w-full h-full bg-primary rounded-lg"
                      />
                    )}
                  </button>
                ))}
              </div>
              {activeForm === "billing" && (
                <motion.div
                  variants={containerVariants}
                  initial="hidden"
                  animate="visible"
                  exit="exit"
                >
                  <BillingAddressForm onFormDataChange={handleBillingChange} />
                </motion.div>
              )}
              {activeForm === "shipping" && (
                <motion.div
                  variants={containerVariants}
                  initial="hidden"
                  animate="visible"
                  exit="exit"
                >
                  <ShippingAddressForm onFormDataChange={handleShippingChange} />
                </motion.div>
              )}
            </div>
          </AnimatePresence>
          <div className="right w-full bg-secondary shadow-lg rounded-lg py-10 px-5 md:w-2/5 h-fit">
            <OrderSummery 
              shippingData={formData.shipping}
              billingData={formData.billing}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default CheckoutPage;
