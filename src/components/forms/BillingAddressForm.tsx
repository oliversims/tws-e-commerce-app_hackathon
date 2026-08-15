"use client";

import AddressForm, { type AddressFormValues } from "./AddressForm";

interface BillingAddressFormProps {
  onFormDataChange: (data: AddressFormValues) => void;
}

const BillingAddressForm = ({ onFormDataChange }: BillingAddressFormProps) => (
  <AddressForm
    kind="billing"
    heading="Billing Address"
    onFormDataChange={onFormDataChange}
  />
);

export default BillingAddressForm;
