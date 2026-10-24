from datetime import date
from django.core.management.base import BaseCommand
from accounts.models import User
from profiles.models import Profile
from matches.models import MatchRequest
from chat.models import Message

class Command(BaseCommand):
    help = 'Seeds the database with admin user and sample Indian matrimonial profiles.'

    def handle(self, *args, **options):
        self.stdout.write('Seeding database for Dil Kaa Rista...')

        # 1. Create Superuser / Admin
        admin_email = 'admin@dilkaarista.com'
        if not User.objects.filter(email=admin_email).exists():
            admin_user = User.objects.create_superuser(
                email=admin_email,
                password='Admin@123',
                full_name='System Administrator',
                gender='male'
            )
            self.stdout.write(self.style.SUCCESS(f'Created Admin: {admin_email} / Admin@123'))

        # 2. Sample Profiles Data
        seed_users = [
            {
                'email': 'priya.sharma@example.com',
                'password': 'Password@123',
                'full_name': 'Priya Sharma',
                'gender': 'female',
                'profile': {
                    'date_of_birth': date(1998, 5, 14),
                    'marital_status': 'Never Married',
                    'height_cm': 165,
                    'religion': 'Hindu',
                    'mother_tongue': 'Hindi',
                    'caste': 'Brahmin',
                    'gotra': 'Vashishta',
                    'city': 'New Delhi',
                    'state': 'Delhi',
                    'country': 'India',
                    'education': 'B.Tech in Computer Science (IIT Delhi)',
                    'occupation': 'Senior Software Engineer at Google',
                    'annual_income': '25 - 35 Lakhs',
                    'about_me': 'Outgoing, ambitious, and family-oriented. Love traveling, classical dance, and exploring new cuisines.',
                    'avatar_url': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=600&auto=format&fit=crop&q=80',
                    'photos': [
                        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800&auto=format&fit=crop&q=80',
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80'
                    ],
                    'is_verified': True,
                    'is_photo_locked': False
                }
            },
            {
                'email': 'aarav.patel@example.com',
                'password': 'Password@123',
                'full_name': 'Aarav Patel',
                'gender': 'male',
                'profile': {
                    'date_of_birth': date(1995, 11, 20),
                    'marital_status': 'Never Married',
                    'height_cm': 180,
                    'religion': 'Hindu',
                    'mother_tongue': 'Gujarati',
                    'caste': 'Patel / Leva',
                    'gotra': 'Kashyap',
                    'city': 'Ahmedabad',
                    'state': 'Gujarat',
                    'country': 'India',
                    'education': 'MBA (IIM Ahmedabad), B.Tech',
                    'occupation': 'VP Product Management at Fintech Startup',
                    'annual_income': '35 - 50 Lakhs',
                    'about_me': 'Passionate entrepreneur at heart, fitness enthusiast, and avid reader. Looking for an understanding partner who values family and dreams big.',
                    'avatar_url': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=600&auto=format&fit=crop&q=80',
                    'photos': [
                        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80',
                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&auto=format&fit=crop&q=80'
                    ],
                    'is_verified': True,
                    'is_photo_locked': False
                }
            },
            {
                'email': 'ananya.iyer@example.com',
                'password': 'Password@123',
                'full_name': 'Ananya Iyer',
                'gender': 'female',
                'profile': {
                    'date_of_birth': date(1997, 8, 9),
                    'marital_status': 'Never Married',
                    'height_cm': 162,
                    'religion': 'Hindu',
                    'mother_tongue': 'Tamil',
                    'caste': 'Iyer / Vadama',
                    'gotra': 'Bharadwaja',
                    'city': 'Bengaluru',
                    'state': 'Karnataka',
                    'country': 'India',
                    'education': 'MS in Data Science (Columbia University)',
                    'occupation': 'Lead Data Scientist at Tech Firm',
                    'annual_income': '30 - 45 Lakhs',
                    'about_me': 'Warm-hearted, progressive yet rooted in cultural traditions. Carnatic music lover and weekend hiker.',
                    'avatar_url': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=600&auto=format&fit=crop&q=80',
                    'photos': [
                        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&auto=format&fit=crop&q=80'
                    ],
                    'is_verified': True,
                    'is_photo_locked': False
                }
            },
            {
                'email': 'rohan.verma@example.com',
                'password': 'Password@123',
                'full_name': 'Rohan Verma',
                'gender': 'male',
                'profile': {
                    'date_of_birth': date(1996, 3, 15),
                    'marital_status': 'Never Married',
                    'height_cm': 178,
                    'religion': 'Hindu',
                    'mother_tongue': 'Hindi',
                    'caste': 'Kayastha',
                    'gotra': 'Shandilya',
                    'city': 'Lucknow',
                    'state': 'Uttar Pradesh',
                    'country': 'India',
                    'education': 'MBBS, MD (AIIMS)',
                    'occupation': 'Consultant Cardiologist',
                    'annual_income': '40 - 60 Lakhs',
                    'about_me': 'Dedicated doctor with a calm demeanor. Believes in mutual respect, laughter, and lifelong partnership.',
                    'avatar_url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=600&auto=format&fit=crop&q=80',
                    'photos': [
                        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80'
                    ],
                    'is_verified': True,
                    'is_photo_locked': False
                }
            },
            {
                'email': 'sneha.gupta@example.com',
                'password': 'Password@123',
                'full_name': 'Sneha Gupta',
                'gender': 'female',
                'profile': {
                    'date_of_birth': date(1999, 1, 22),
                    'marital_status': 'Never Married',
                    'height_cm': 160,
                    'religion': 'Hindu',
                    'mother_tongue': 'Hindi',
                    'caste': 'Bania / Agarwal',
                    'gotra': 'Garg',
                    'city': 'Jaipur',
                    'state': 'Rajasthan',
                    'country': 'India',
                    'education': 'Chartered Accountant (CA)',
                    'occupation': 'Senior Financial Analyst at Big 4',
                    'annual_income': '20 - 30 Lakhs',
                    'about_me': 'Lively, creative, and passionate about financial independence. Enjoys painting, photography, and road trips.',
                    'avatar_url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop&q=80',
                    'photos': [
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80'
                    ],
                    'is_verified': True,
                    'is_photo_locked': False
                }
            },
            {
                'email': 'kabir.kapoor@example.com',
                'password': 'Password@123',
                'full_name': 'Kabir Kapoor',
                'gender': 'male',
                'profile': {
                    'date_of_birth': date(1994, 7, 4),
                    'marital_status': 'Never Married',
                    'height_cm': 183,
                    'religion': 'Hindu',
                    'mother_tongue': 'Punjabi',
                    'caste': 'Khatri',
                    'gotra': 'Kapoor',
                    'city': 'Mumbai',
                    'state': 'Maharashtra',
                    'country': 'India',
                    'education': 'Master of Design (NID)',
                    'occupation': 'Principal UX Architect',
                    'annual_income': '30 - 45 Lakhs',
                    'about_me': 'Design thinker, coffee connoisseur, and dog lover. Looking for someone genuine to create a beautiful life story together.',
                    'avatar_url': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=600&auto=format&fit=crop&q=80',
                    'photos': [
                        'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=800&auto=format&fit=crop&q=80'
                    ],
                    'is_verified': True,
                    'is_photo_locked': False
                }
            },
            {
                'email': 'diya.singh@example.com',
                'password': 'Password@123',
                'full_name': 'Diya Singh',
                'gender': 'female',
                'profile': {
                    'date_of_birth': date(1996, 10, 18),
                    'marital_status': 'Never Married',
                    'height_cm': 168,
                    'religion': 'Sikh',
                    'mother_tongue': 'Punjabi',
                    'caste': 'Jat Sikh',
                    'gotra': 'Gill',
                    'city': 'Chandigarh',
                    'state': 'Punjab',
                    'country': 'India',
                    'education': 'LL.M in Corporate Law',
                    'occupation': 'Senior Corporate Legal Counsel',
                    'annual_income': '25 - 40 Lakhs',
                    'about_me': 'Articulate, thoughtful, and compassionate. Loves horse riding, history, and meaningful conversations.',
                    'avatar_url': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600&auto=format&fit=crop&q=80',
                    'photos': [
                        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&auto=format&fit=crop&q=80'
                    ],
                    'is_verified': True,
                    'is_photo_locked': False
                }
            },
            {
                'email': 'vikram.reddy@example.com',
                'password': 'Password@123',
                'full_name': 'Vikram Reddy',
                'gender': 'male',
                'profile': {
                    'date_of_birth': date(1995, 12, 5),
                    'marital_status': 'Never Married',
                    'height_cm': 175,
                    'religion': 'Hindu',
                    'mother_tongue': 'Telugu',
                    'caste': 'Reddy',
                    'gotra': 'Kashyap',
                    'city': 'Hyderabad',
                    'state': 'Telangana',
                    'country': 'India',
                    'education': 'MS Computer Engineering',
                    'occupation': 'Cloud Solutions Architect at AWS',
                    'annual_income': '35 - 55 Lakhs',
                    'about_me': 'Calm, grounded, and loves technology and badminton. Seeking a partner who appreciates simple joys and mutual encouragement.',
                    'avatar_url': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=600&auto=format&fit=crop&q=80',
                    'photos': [
                        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800&auto=format&fit=crop&q=80'
                    ],
                    'is_verified': True,
                    'is_photo_locked': False
                }
            }
        ]

        created_users = {}
        for item in seed_users:
            user, created = User.objects.get_or_create(
                email=item['email'],
                defaults={
                    'full_name': item['full_name'],
                    'gender': item['gender'],
                }
            )
            if created:
                user.set_password(item['password'])
                user.save()
            created_users[item['email']] = user

            # Profile
            profile, _ = Profile.objects.get_or_create(user=user)
            for k, v in item['profile'].items():
                setattr(profile, k, v)
            profile.verification_status = 'approved'
            profile.is_verified = True
            if not profile.membership_tier:
                profile.membership_tier = 'tier_2' if item['email'].startswith('priya') else 'tier_1'
            profile.save()

            # Partner Preferences
            from profiles.models import PartnerPreference
            pref, _ = PartnerPreference.objects.get_or_create(profile=profile)
            pref.religion = ['Hindu']
            pref.marital_status = ['Never Married']
            pref.must_have_fields = ['religion', 'marital_status']
            pref.age_min = 22
            pref.age_max = 35
            pref.save()
            self.stdout.write(f"Synced profile for: {user.full_name} ({user.gender}) - {profile.profile_id}")

        # 3. Create Sample Match Request, Shortlist, and Photo Requests
        from matches.models import Shortlist, PhotoOrContactRequest
        priya = created_users.get('priya.sharma@example.com')
        aarav = created_users.get('aarav.patel@example.com')
        if priya and aarav:
            MatchRequest.objects.get_or_create(
                sender=aarav,
                receiver=priya,
                defaults={'status': 'pending', 'message': 'Namaste Priya, I really liked your profile!'}
            )
            Message.objects.get_or_create(
                sender=aarav,
                receiver=priya,
                content='Hello Priya! Glad to connect on Dil Kaa Rista.'
            )
            Shortlist.objects.get_or_create(user=aarav, profile=priya.profile)
            Shortlist.objects.get_or_create(user=priya, profile=aarav.profile)
            PhotoOrContactRequest.objects.get_or_create(
                sender=aarav,
                receiver=priya,
                request_type='contact',
                defaults={'status': 'pending'}
            )

        self.stdout.write(self.style.SUCCESS('Successfully seeded database for Dil Kaa Rista!'))

