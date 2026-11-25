import React, { useState } from 'react';

interface WorkerAvatarProps {
  name: string;
  role?: string;
  avatarUrl?: string;
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

const SIZE_CLASSES: Record<NonNullable<WorkerAvatarProps['size']>, string> = {
  xs: 'w-8 h-8 text-xs',
  sm: 'w-10 h-10 text-xs',
  md: 'w-12 h-12 text-sm',
  lg: 'w-16 h-16 text-base',
  xl: 'w-20 h-20 text-lg',
};

export const WorkerAvatar: React.FC<WorkerAvatarProps> = ({
  name,
  role,
  avatarUrl,
  size = 'md',
  className = '',
}) => {
  const [imgFailed, setImgFailed] = useState(false);

  const initials = name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? '')
    .join('');

  if (avatarUrl && !imgFailed) {
    return (
      <img
        src={avatarUrl}
        alt={role ? `${name}, ${role}` : name}
        referrerPolicy="no-referrer"
        onError={() => setImgFailed(true)}
        className={`${SIZE_CLASSES[size]} rounded-full object-cover object-top shrink-0 border border-slate-200 dark:border-slate-700 bg-slate-100 dark:bg-slate-800 ${className}`}
      />
    );
  }

  return (
    <div
      aria-label={name}
      className={`${SIZE_CLASSES[size]} rounded-full shrink-0 flex items-center justify-center font-semibold tracking-tight bg-[#0F594E]/10 text-[#0F594E] dark:bg-[#14B8A6]/15 dark:text-[#5EEAD4] border border-[#0F594E]/15 dark:border-[#14B8A6]/25 ${className}`}
    >
      {initials || 'HE'}
    </div>
  );
};
