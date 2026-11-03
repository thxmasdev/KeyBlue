import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'http://localhost:54321';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export interface License {
  id: string;
  key_prefix: string;
  license_type: 'permanent' | '30_days' | '90_days' | 'annual' | 'custom';
  status: 'available' | 'active' | 'expired' | 'revoked' | 'suspended';
  expires_at: string | null;
  max_devices: number;
  created_at: string;
  revoked_at: string | null;
}

export interface Activation {
  id: string;
  license_id: string;
  device_id: string;
  device_name: string;
  activated_at: string;
  last_validated_at: string;
}

export interface AuditLog {
  id: string;
  admin_id: string;
  action: string;
  target_id: string;
  metadata: any;
  created_at: string;
}

