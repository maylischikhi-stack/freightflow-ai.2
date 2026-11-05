export type ShipmentDocument = {
 id:string; shipment_id:string|null; file_name:string; document_type:string;
 status:"uploaded"|"processing"|"review"|"validated"|"error";
 extracted_data:Record<string,unknown>|null; created_at:string;
};
