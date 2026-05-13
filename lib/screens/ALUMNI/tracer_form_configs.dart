part of 'tracer_form_page.dart';

const Map<String, _ProgramConfig> _tracerFormConfigs = {
  'BSIT': _bsitTracerConfig,
  'BSSW': _bsswTracerConfig,
  'GENERIC': _genericTracerConfig,
};

_ProgramConfig _tracerConfigForProgram(String programCode) {
  final normalized = programCode.trim().toUpperCase();
  return _tracerFormConfigs[normalized] ?? _genericTracerConfig;
}

// Add future program-specific tracer forms here instead of creating one Dart
// page per program. Example: add 'BSCRIM': _bscrimTracerConfig above, then
// define the _ProgramConfig below.
const _ProgramConfig _genericTracerConfig = _ProgramConfig(
  programCode: 'GENERIC',
  programTitle: 'Graduate Tracer Study Questionnaire',
  programSubtitle:
      'General tracer form template for programs without an approved custom survey yet',
  currentJobRelatedLabel:
      '21. Is your current job related to your completed program?',
  studyTypeOptions: ['Certificate', 'Masteral', 'Doctorate', 'Others'],
  licensureLabel: '35. Did you take any board or licensure exam?',
  licensureTypeLabel: 'If yes, what is the type of licensure exam?',
  licensureResultLabel: 'If yes, result',
  skillsOptions: [
    'Communication Skills',
    'Critical Thinking',
    'Problem-Solving',
    'Teamwork and Collaboration',
    'Leadership',
    'Research Skills',
    'Digital Literacy',
    'Professional Ethics',
    'Adaptability and Continuous Learning',
    'Time Management and Work Ethics',
  ],
  peoStatements: [
    'Demonstrate professional competence in their chosen field.',
    'Apply ethical standards and social responsibility in professional practice.',
    'Engage in lifelong learning and career development.',
  ],
  curriculumSatisfactionLabel: 'Curriculum relevance to professional practice',
  recommendationLabel:
      '56. How likely are you to recommend your program to others?',
  reputationLabel:
      '57. How would you describe the institution and program reputation in your field?',
  feedbackCompetenciesLabel:
      '59. What specific competencies should be strengthened in the curriculum?',
);

const _ProgramConfig _bsswTracerConfig = _ProgramConfig(
  programCode: 'BSSW',
  programTitle: 'BS Social Work Graduate Tracer Study Questionnaire',
  programSubtitle:
      'Aligned with CHED QA Indicators, AUN-QA, ISO 9001:2015, and QILT GOS-L Benchmarks',
  currentJobRelatedLabel: '21. Is your current job related to social work?',
  studyTypeOptions: ['Certificate', 'MA/MSW', 'PhD', 'Others'],
  licensureLabel: '35. Did you take the Social Work Licensure Exam?',
  licensureTypeLabel: 'Licensure exam type',
  licensureResultLabel: 'If yes, result',
  skillsOptions: [
    'Casework and counseling skills',
    'Community organizing and development',
    'Social policy analysis',
    'Advocacy and networking',
    'Research and evaluation',
    'Ethical decision-making',
    'Documentation and report writing',
    'Supervision and mentoring',
    'Use of ICT tools for social work',
  ],
  peoStatements: [
    'Demonstrate knowledge, skills, and attitudes in generalist helping processes and planned change for therapeutic, protective, preventive, and transformative purposes.',
    'Analyze critically the origin, development, and purposes of social work in the Philippines.',
    'Critique the impacts of global and national socio-structural inadequacies, discrimination, and oppression on quality of life.',
    'Apply knowledge of human behavior and social environment emphasizing person-in-situation dynamics in assessment and intervention.',
    'Critique social welfare policies, programs, and services in terms of relevance, responsiveness, accessibility, and availability.',
    'Engage in advocacy work to promote socio-economic and cultural rights and well-being.',
    'Generate resources for networking and partnership development.',
    'Identify with the social work profession and conduct oneself in accordance with social work values and ethics.',
    'Engage in social work practices that promote diversity and inclusion among client systems.',
    'Use supervision to develop critical self-reflective practice for professional growth.',
    'Produce and maintain portfolios, recordings, and case documentation reflecting quality practice.',
  ],
  curriculumSatisfactionLabel: 'Curriculum relevance to social work practice',
  recommendationLabel:
      '56. How likely are you to recommend JMCFI\'s Social Work program to others?',
  reputationLabel:
      '57. How would you describe JMCFI\'s reputation in the social work community?',
  feedbackCompetenciesLabel:
      '59. What specific competencies should be strengthened in the BSSW curriculum?',
);

const _ProgramConfig _bsitTracerConfig = _ProgramConfig(
  programCode: 'BSIT',
  programTitle: 'BS Information Technology Graduate Tracer Study Questionnaire',
  programSubtitle:
      'Aligned with CHED QA Indicators, AUN-QA, ISO 9001:2015, and QILT GOS-L Benchmarks',
  currentJobRelatedLabel: '21. Is your current job related to IT?',
  studyTypeOptions: ['Certificate', 'MIT/MIS', 'PhD/DIT/DBMIS', 'Others'],
  licensureLabel: '35. Did you take any board or licensure exam?',
  licensureTypeLabel: 'If yes, what is the type of licensure exam?',
  licensureResultLabel: 'If yes, result',
  skillsOptions: [
    'Programming and Software Development',
    'Database Management',
    'Networking and Cybersecurity',
    'Systems Analysis and Design',
    'Cloud Computing and DevOps',
    'Problem-Solving and Critical Thinking',
    'Debugging and Troubleshooting',
    'Communication Skills',
    'Teamwork and Collaboration',
    'Time Management and Work Ethics',
    'Adaptability and Continuous Learning',
    'UI/UX Design',
    'Version Control (e.g., Git)',
    'AI / Data Analytics Awareness',
  ],
  peoStatements: [
    'Demonstrate a strong foundation in IT principles and practices, enabling them to effectively create and implement solutions to real-world problems.',
    'Demonstrate leadership and innovation, taking initiative to lead projects, drive technological advancements, and contribute to organizational success.',
    'Engage in continuous learning and professional development to adapt to the evolving field of information technology.',
  ],
  curriculumSatisfactionLabel: 'Curriculum relevance to IT practice',
  recommendationLabel:
      '56. How likely are you to recommend JMCFI\'s BSIT program to others?',
  reputationLabel:
      '57. How would you describe JMCFI\'s reputation in the IT community?',
  feedbackCompetenciesLabel:
      '59. What specific competencies should be strengthened in the BSIT curriculum?',
);
