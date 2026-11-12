class TeamMember {
  final String name;
  final String rollNo;
  final String role;

  const TeamMember(this.name, this.rollNo, this.role);
}

const String universityName = 'COMSATS University Islamabad';
const String courseName = 'Mobile Application Development';
const String appVersion = '1.0.0';

const List<TeamMember> teamMembers = [
  TeamMember('Areeb Tahir', 'FA23-BCS-468',
      'Camera, import and document library'),
  TeamMember('Sohaib Dost', 'SP24-BCS-030',
      'Crop, image processing, PDF, files and sharing'),
];
