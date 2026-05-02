-- Circle App - Complete Database Schema
-- Copy and paste this entire file into Supabase SQL Editor
-- Then click "Run" to create all tables and policies

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLES
-- ============================================================================

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
  id UUID REFERENCES auth.users PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  status TEXT DEFAULT 'Available',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Circles table
CREATE TABLE public.circles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('duo', 'themed')),
  theme TEXT,
  created_by UUID REFERENCES public.users NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Circle members
CREATE TABLE public.circle_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  circle_id UUID REFERENCES public.circles ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users ON DELETE CASCADE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'member')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(circle_id, user_id)
);

-- Messages
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  circle_id UUID REFERENCES public.circles ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users ON DELETE CASCADE NOT NULL,
  content TEXT,
  type TEXT NOT NULL CHECK (type IN ('text', 'image', 'voice', 'location')),
  media_url TEXT,
  parent_id UUID REFERENCES public.messages ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  edited_at TIMESTAMP WITH TIME ZONE
);

-- Demands
CREATE TABLE public.demands (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  circle_id UUID REFERENCES public.circles ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN ('food', 'pickup', 'gift', 'other')),
  priority TEXT NOT NULL CHECK (priority IN ('essential', 'if_possible', 'gift')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Demand reactions
CREATE TABLE public.demand_reactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  demand_id UUID REFERENCES public.demands ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('heart', 'comment')),
  content TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Photos
CREATE TABLE public.photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  circle_id UUID REFERENCES public.circles ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users ON DELETE CASCADE NOT NULL,
  url TEXT NOT NULL,
  thumbnail_url TEXT,
  caption TEXT,
  location TEXT,
  taken_at TIMESTAMP WITH TIME ZONE,
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Milestones
CREATE TABLE public.milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  circle_id UUID REFERENCES public.circles ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  date DATE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('anniversary', 'birthday', 'custom')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- INDEXES (for better performance)
-- ============================================================================

CREATE INDEX idx_messages_circle_id ON public.messages(circle_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX idx_demands_circle_id ON public.demands(circle_id);
CREATE INDEX idx_demands_status ON public.demands(status);
CREATE INDEX idx_photos_circle_id ON public.photos(circle_id);
CREATE INDEX idx_photos_uploaded_at ON public.photos(uploaded_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.circles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.circle_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demand_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestones ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Users policies
CREATE POLICY "Users can view their own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Circles policies
CREATE POLICY "Users can view circles they're members of" ON public.circles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = circles.id
      AND circle_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create circles" ON public.circles
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Admins can update their circles" ON public.circles
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = circles.id
      AND circle_members.user_id = auth.uid()
      AND circle_members.role = 'admin'
    )
  );

CREATE POLICY "Admins can delete their circles" ON public.circles
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = circles.id
      AND circle_members.user_id = auth.uid()
      AND circle_members.role = 'admin'
    )
  );

-- Circle members policies
CREATE POLICY "Users can view members of their circles" ON public.circle_members
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.circle_members cm
      WHERE cm.circle_id = circle_members.circle_id
      AND cm.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can add members" ON public.circle_members
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_id = circle_members.circle_id
      AND user_id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "Admins can remove members" ON public.circle_members
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.circle_members cm
      WHERE cm.circle_id = circle_members.circle_id
      AND cm.user_id = auth.uid()
      AND cm.role = 'admin'
    )
  );

-- Messages policies
CREATE POLICY "Users can view messages in their circles" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = messages.circle_id
      AND circle_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can send messages to their circles" ON public.messages
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = messages.circle_id
      AND circle_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own messages" ON public.messages
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own messages" ON public.messages
  FOR DELETE USING (auth.uid() = user_id);

-- Demands policies
CREATE POLICY "Users can view demands in their circles" ON public.demands
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = demands.circle_id
      AND circle_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create demands in their circles" ON public.demands
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = demands.circle_id
      AND circle_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update demands in their circles" ON public.demands
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = demands.circle_id
      AND circle_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their own demands" ON public.demands
  FOR DELETE USING (auth.uid() = user_id);

-- Demand reactions policies
CREATE POLICY "Users can view reactions in their circles" ON public.demand_reactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.demands d
      JOIN public.circle_members cm ON d.circle_id = cm.circle_id
      WHERE d.id = demand_reactions.demand_id
      AND cm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can add reactions in their circles" ON public.demand_reactions
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM public.demands d
      JOIN public.circle_members cm ON d.circle_id = cm.circle_id
      WHERE d.id = demand_reactions.demand_id
      AND cm.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their own reactions" ON public.demand_reactions
  FOR DELETE USING (auth.uid() = user_id);

-- Photos policies
CREATE POLICY "Users can view photos in their circles" ON public.photos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = photos.circle_id
      AND circle_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can upload photos to their circles" ON public.photos
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = photos.circle_id
      AND circle_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own photos" ON public.photos
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own photos" ON public.photos
  FOR DELETE USING (auth.uid() = user_id);

-- Milestones policies
CREATE POLICY "Users can view milestones in their circles" ON public.milestones
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = milestones.circle_id
      AND circle_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create milestones in their circles" ON public.milestones
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = milestones.circle_id
      AND circle_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update milestones in their circles" ON public.milestones
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = milestones.circle_id
      AND circle_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete milestones in their circles" ON public.milestones
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.circle_members
      WHERE circle_members.circle_id = milestones.circle_id
      AND circle_members.user_id = auth.uid()
    )
  );

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'display_name');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update last_seen timestamp
CREATE OR REPLACE FUNCTION public.update_last_seen()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users
  SET last_seen = NOW()
  WHERE id = auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- COMPLETED!
-- ============================================================================

-- If you see this message, all tables and policies were created successfully!
-- Next steps:
-- 1. Go to Table Editor to verify all 9 tables exist
-- 2. Create storage buckets (avatars, photos, voice-notes)
-- 3. Enable real-time for messages and demands tables
