-- this file was manually created
INSERT INTO public.users (display_name, handle, email, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown','andrew@exampro.co', 'MOCK'),
  ('Mahmoudgooda', 'MGOODA', 'mgooda.gamer@gmail.com', 'MOCK'),
  ('Little Gooda', 'LTG', 'mahmoud.gooda@gmail.com', 'MOCK'),
  ('Andrew Bayko', 'bayko','bayko@exampro.co', 'MOCK'),
  ('Londo Mollari', 'lmollari', 'lmollari@centri.com', 'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'MGOODA' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  ),

  (
    (SELECT uuid from public.users WHERE users.handle = 'LTG' LIMIT 1),
    'This post from the other user!',
    current_timestamp + interval '10 day'
  );