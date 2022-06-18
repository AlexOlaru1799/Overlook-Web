class Globals {
  static bool firstLoadProfile = false;
  static bool firstLoadNavbar = false;

  static void changeFirstLoadProfile() {
    firstLoadProfile = true;
  }

  static bool getFirstLoadProfile() {
    return firstLoadProfile;
  }

  static void changeFirstLoadNavbar() {
    firstLoadNavbar = true;
  }

  static bool getFirstLoadNavbar() {
    return firstLoadNavbar;
  }
}
