"use client";

import AddressForm, { type AddressFormValues } from "./AddressForm";

interface ShippingAddressFormProps {
  onFormDataChange: (data: AddressFormValues) => void;
}

const ShippingAddressForm = ({ onFormDataChange }: ShippingAddressFormProps) => (
  <AddressForm
    kind="shipping"
    heading="Shipping Address"
    onFormDataChange={onFormDataChange}
  />
);

export default ShippingAddressForm;
