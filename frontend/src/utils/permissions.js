export const ROLES = {
  ADMIN: 'ADMIN',
  OPERATOR: 'OPERATOR',
  VIEWER: 'VIEWER',
};

export const canEditSettings = (role) => {
  return role === ROLES.ADMIN || role === ROLES.OPERATOR;
};

export const canManageUsers = (role) => {
  return role === ROLES.ADMIN;
};

export const canControlDevices = (role) => {
  return role === ROLES.ADMIN || role === ROLES.OPERATOR;
};