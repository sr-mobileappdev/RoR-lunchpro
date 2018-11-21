class Provider < ApplicationRecord
  include LunchproRecord

  # Per dnovak: And a provider can only be associated with 1 office at a time, so if a Dr actually worked at 2..  then there would be 2 listings for that Dr. The system would have no idea it's the same provider
  # Providers at more than one office is NOT supported. They would become a unique provider per office
  has_many :offices_providers, dependent: :destroy
  has_many :offices, through: :offices_providers
  has_and_belongs_to_many :diet_restrictions
  has_many :provider_availabilities, dependent: :destroy
  has_many :provider_exclude_dates, dependent: :destroy

  accepts_nested_attributes_for :provider_exclude_dates, allow_destroy: true
  accepts_nested_attributes_for :provider_availabilities, allow_destroy: true
  # -- Validates

  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  enum day_of_week: {
    monday: Constants::DOW_MONDAY,
    tuesday: Constants::DOW_TUESDAY,
    wednesday: Constants::DOW_WEDNESDAY,
    thursday: Constants::DOW_THURSDAY,
    friday: Constants::DOW_FRIDAY,
    saturday: Constants::DOW_SATURDAY,
    sunday: Constants::DOW_SUNDAY
  }

  def create_validations
    unless title.present?
      self.errors.add(:base, "Title must be provided for the provider.")
    end
    unless first_name.present?
      self.errors.add(:base, "First name must be provided for the provider.")
    end
    unless last_name.present?
      self.errors.add(:base, "Last name must be provided for the provider.")
    end
  end

  def update_validations
    unless title.present?
      self.errors.add(:base, "Title must be provided for the provider.")
    end
    unless first_name.present?
      self.errors.add(:base, "First name must be provided for the provider.")
    end
    unless last_name.present?
      self.errors.add(:base, "Last name must be provided for the provider.")
    end
  end


  def self.for_office_ids(office_ids)
    active.joins(:offices_providers).where(offices_providers: {office_id: office_ids}).order(last_name: :asc)
  end

  def display_name
    "#{title} #{first_name} #{last_name}"
  end

  def office
    offices.first
  end

  def office_name
    offices.first ? offices.first.name : nil
  end

  def office_id
    offices.first ? offices.first.id : nil

  end

  def formatted_specialties
    specialties.join(", ")
  end

  # Limit to 1 only per the note at top of model
  def assign_to_office(office)
    if offices && offices.first != office
      office.providers << self
      office.save
    elsif offices.count > 1
      self.offices = []
      office.providers << self
      self.save
      office.save
    end
  end
=begin
  def available_at(slot)
    day_of_weeks = AppointmentSlot.day_of_weeks
    provider_availabilities.active.where("day_of_week = ? and starts_at < ? and ends_at > ?", day_of_weeks[slot.day_of_week], slot.starts_at.to_s, slot.ends_at.to_s).exists?
  end
=end
  def availability_by_day
    by_day = {"monday" => [], "tuesday" => [], "wednesday" => [], "thursday" => [], "friday" => [], "saturday" => [], "sunday" => []}
    provider_availabilities.by_time.each do |s|
      s.starts_at = s.starts_at(true)
      s.ends_at = s.ends_at(true)
      by_day[s.day_of_week] << s
    end

    by_day
  end

  def diet_summary
    if diet_restrictions.count > 0
      diet_restrictions.map { |d| d.name }.flatten.compact.join(", ")
    else
      nil
    end
  end

  def self.__columns
    cols = {display_name: 'Name'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

  def self.specialties
    [
      "Abdominal Radiology",
      "Addiction Psychiatry",
      "Adolescent Medicine",
      "Adult Cardiothoracic Anesthesiology",
      "Adult Reconstructive Orthopedics",
      "Advanced Heart Failure & Transplant Cardiology",
      "Allergy & Immunology",
      "Aerospace Medicine",
      "Anesthesiology",
      "Biochemical Genetics",
      "Blood Banking - Transfusion Medicine",
      "Cardiology",
      "Cardiothoracic Radiology",
      "Cardiothoracic Surgery",
      "Cardiovascular Disease",
      "Chemical Pathology ",
      "Child & Adolescent Psychiatry",
      "Child & Adolescent Psychotherapy",
      "Child Abuse Pediatrics",
      "Child Neurology",
      "Clinical Biology",
      "Clinical Chemistry",
      "Clinical Neurophysiology",
      "Clinical & Laboratory Immunology",
      "Clinical Cardiac Electrophysiology",
      "Clinical Neurophysiology",
      "Colon & Rectal Surgery",
      "Congenital Cardiac Surgery",
      "Craniofacial Surgery",
      "Critical Care Medicine",
      "Cytopathology",
      "Dental/Oral and Maxillofacial Surgery",
      "Dermatology",
      "Dermatology - Venereology",
      "Dermatopathology",
      "Developmental-Behavioral Pediatrics",
      "Emergency Medicine",
      "Endocrinology",
      "Endocrinology - Diabetes & Metabolism",
      "Endocrinology Surgical Neuroradiology",
      "Family Medicine",
      "Family Practice",
      "Female Pelvic Medicine & Reconstructive Surgery",
      "Foot & Ankle Orthopedics",
      "Forensic Pathology",
      "Forensic Psychiatry",
      "Gastroenterology",
      "General Practice",
      "Geriatrics",
      "Geriatric Medicine",
      "Geriatric Psychiatry",
      "Hand Surgery",
      "Health Informatics",
      "Hematology",
      "Hematology & Oncology",
      "Hospice and Palliative Medicine",
      "Infectious Disease",
      "Internal Medicine",
      "Internal Medicine - Pediatrics",
      "Interventional Cardiology",
      "Interventional Radiology",
      "Laboratory Medicine",
      "Maxillofacial Surgery",
      "Medical Genetics",
      "Medical Microbiology",
      "Medical Toxicology",
      "Microbiology",
      "Molecular Genetic Pathology",
      "Musculoskeletal Radiology",
      "Musculoskeletal Oncology",
      "Neonatology",
      "Neonatal-Perinatal Medicine",
      "Nephrology",
      "Neurosurgery",
      "Neurological Surgery",
      "Neurology ",
      "Neuromuscular Medicine",
      "Neuropathology",
      "Nuclear Medicine",
      "Nuclear Radiology",
      "Obstetric Anesthesiology",
      "Obstetrics & Gynecology",
      "Occupational Medicine",
      "Oncology",
      "Ophthalmic Plastic & Reconstructive Surgery",
      "Ophthalmology",
      "Oral and Maxillofacial Surgery",
      "Orthodontics",
      "Orthopedics",
      "Orthopedic Sports Medicine",
      "Orthopedic Surgery",
      "Orthopedic Surgery of the Spine",
      "Orthopedic Trauma",
      "Otorhinolaryngology",
      "Otolaryngology",
      "Otology - Neurology",
      "Pain Medicine",
      "Pathology ",
      "Pathology-Anatomic & Clinical",
      "Pediatrics",
      "Pediatric Anesthesiology",
      "Pediatric Cardiology",
      "Pediatric Critical Care Medicine",
      "Pediatric Diabetes",
      "Pediatric Emergency Medicine",
      "Pediatric Endocrinology",
      "Pediatric Gastroenterology",
      "Pediatric Hematology-Oncology",
      "Pediatric Hepatology",
      "Pediatric Infectious Diseases ",
      "Pediatric Nephrology",
      "Pediatric Nutrition",
      "Pediatric Oncology",
      "Pediatric Orthopedics",
      "Pediatric Otolaryngology",
      "Pediatric Pathology",
      "Pediatric Pulmonology",
      "Pediatric Radiology",
      "Pediatric Respiratory Medicine",
      "Pediatric Rheumatology",
      "Pediatric Sports Medicine",
      "Pediatric Surgery",
      "Pediatric Transplant Hepatology",
      "Pediatric Urology",
      "Pediatrics",
      "Physical Medicine & Rehabilitation",
      "Plastic Reconstructive and Aesthetic Surgery",
      "Plastic Surgery",
      "Podiatry",
      "Preventive Medicine",
      "Procedural Dermatology",
      "Psychiatry",
      "Public Health",
      "Pulmonary Disease",
      "Pulmonary Disease & Critical Care Medicine",
      "Pulmonology",
      "Radiation Oncology",
      "Radiology ",
      "Radiology-Diagnostic",
      "Rheumatology",
      "Sleep Medicine",
      "Spinal Cord Injury Medicine",
      "Sports Medicine",
      "Surgery - General",
      "Surgical Critical Care",
      "Thoracic Surgery",
      "Thoracic Surgery-Integrated",
      "Transplant Hepatology",
      "Urology",
      "Vascular Medicine",
      "Vascular & Interventional Radiology",
      "Vascular Surgery",
      "Venereology"
    ]
  end

  def self.titles
    [
     {
        title: "M.D.",
        description: "Medical Doctor"
     },
     {
       title: "P.A.",
       description: "Physician Assistant"
     },
     {
       title: "N.P.",
       description: "Nurse Practitioner"
     },
     {
       title: "A.U.",
       description: "Audiologist"
     },
     {
       title: "AE-C",
       description: "Certified Asthma Educator"
     },
     {
       title: "ANP",
       description: "Adult Nurse Practitioner"
     },
     {
       title: "ATC",
       description: "Certified Athletic Trainer"
     },
     {
       title: "Au.D.",
       description: "Doctorate of Audiology"
     },
     {
       title: "B.C.-ADM",
       description: "Board Certified, American Diabetic Association"
     },
     {
       title: "B.S.",
       description: "Bachelor of Science"
     },
     {
       title: "BSN",
       description: "Bachelor of Science in Nursing"
     },
     {
       title: "CCC-A",
       description: "Certificate of Clinical Competence in Audiology "
     },
     {
       title: "CCC-SLP",
       description: "Certificate of Clinical Competence in Speech-Language Pathology"
     },
     {
       title: "CCRN",
       description: "Critical Care Registered Nurse"
     },
     {
       title: "CDE",
       description: "Certified Diabetes Educator "
     },
     {
       title: "CDTC",
       description: "Certified Diabetes Technology Clinician"
     },
     {
       title: "CFNP",
       description: "Certified Family Nurse Practitioner "
     },
     {
       title: "CGC",
       description: "Certified Genetic Counselor"
     },
     {
       title: "CHT",
       description: "Certified Hand Therapist"
     },
     {
       title: "CLE",
       description: "Certified Lactation Educator"
     },
     {
       title: "CMA",
       description: "Certified Medical Assistant "
     },
     {
       title: "CNM",
       description: "Certified Nurse Midwife"
     },
     {
       title: "CNS",
       description: "Clinical Nurse Specialist"
     },
     {
       title: "CNSC",
       description: "Certified Nutrition Support Clinician"
     },
     {
       title: "CNSD",
       description: "Certified Nutrition Support Dietitian"
     },
     {
       title: "COMT",
       description: "Certified Ophthalmic Medical Technologist"
     },
     {
       title: "CPM",
       description: "Certified Professional Midwife"
     },
     {
       title: "CSCS",
       description: "Certified Strength and Conditioning Specialist"
     },
     {
       title: "CSO",
       description: "Certified Specialist in Oncology Nutrition"
     },
     {
       title: "CSSD",
       description: "Certified Specialist in Sports Dietetics"
     },
     {
       title: "D.O.",
       description: "Doctor of Osteopathy"
     },
     {
       title: "DPM",
       description: "Doctor of Podiatric Medicine"
     },
     {
       title: "DPT",
       description: "Doctor of Physical Therapy"
     },
     {
       title: "Ed.D.",
       description: "Doctor of Education"
     },
     {
       title: "Ed.S.",
       description: "Educational Specialist"
     },
     {
       title: "FAAP",
       description: "Fellow, American Academy of Pediatrics"
     },
     {
       title: "FAAC",
       description: "Fellow, American College of Cardiology"
     },
     {
       title: "FCCP",
       description: "Fellow, American College of Chest Physicians"
     },
     {
       title: "FACOG",
       description: "Fellow, American College of Obstetrics and Gynecology"
     },
     {
       title: "FNP",
       description: "Family Nurse Practitioner"
     },
     {
       title: "FNP-C",
       description: "Certified Family Nurse Practitioner"
     },
     {
       title: "IBCLC",
       description: "International Board Certified Lactation Consultant"
     },
     {
       title: "L.E.",
       description: "Licensed Esthetician"
     },
     {
       title: "LCSW",
       description: "Licensed Clinical Social Worker"
     },
     {
       title: "M.A.",
       description: "Medical Assistant"
     },
     {
       title: "M.D.",
       description: "Medical Doctor"
     },
     {
       title: "M.S.",
       description: "Master of Science"
     },
     {
       title: "MFT",
       description: "Marriage and Family Therapist"
     },
     {
       title: "MHS",
       description: "Master of Health Science"
     },
     {
       title: "MMS",
       description: "Master of Medical Science"
     },
     {
       title: "MPA",
       description: "Master of Physician Assistant Studies"
     },
     {
       title: "MPH",
       description: "Master of Public Health"
     },
     {
       title: "MPT",
       description: "Master of Physical Therapy"
     },
     {
       title: "MSPAS",
       description: "Master of Science in Physician Assistant Studies"
     },
     {
       title: "MSPT",
       description: "Master of Science in Physical Therapy"
     },
     {
       title: "MSW",
       description: "Master of Social Work"
     },
     {
       title: "N.P.",
       description: "Nurse Practitioner"
     },
     {
       title: "NP-C",
       description: "Certified Nurse Practitioner"
     },
     {
       title: "O.D.",
       description: "Doctor of Optometry"
     },
     {
       title: "OCN",
       description: "Oncology Certified Nurse"
     },
     {
       title: "OCS",
       description: "Orthopedic Clinical Specialist"
     },
     {
       title: "OTR",
       description: "Registered Occupational Therapist"
     },
     {
       title: "P.A.",
       description: "Physician Assistant"
     },
     {
       title: "PA-C",
       description: "Certified Physician Assistant"
     },
     {
       title: "P.T.",
       description: "Physical Therapist"
     },
     {
       title: "Ph.D.",
       description: "Doctor of Philosophy"
     },
     {
       title: "PHN",
       description: "Public Health Nurse"
     },
     {
       title: "Psy D",
       description: "Doctorate of Psychology"
     },
     {
       title: "R.D.",
       description: "Registered Dietitian"
     },
     {
       title: "R.N.",
       description: "Registered Nurse"
     },
     {
       title: "RCP",
       description: "Respiratory Care Practitioner"
     },
     {
       title: "RNC",
       description: "Certified Registered Nurse"
     },
     {
       title: "RNFA",
       description: "Registered Nurse First Assistant"
     },
     {
       title: "SCS",
       description: "Certified Sports Specialist"
     },
     {
       title: "WHNP",
       description: "Women's Health Nurse Practitioner"
     }
]
  end

end
