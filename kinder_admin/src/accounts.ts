// Wspólne pomocnicze funkcje do kont rodziców i dyrektorów

// Domena loginów – loginy mają postać imie.nazwisko@kinder.pl
export const LOGIN_DOMAIN = 'kinder.pl'

// Bez znaków mylących przy przepisywaniu (0/O, 1/l/I)
const PASSWORD_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789'
export const generatePassword = (length = 10) => {
  const bytes = crypto.getRandomValues(new Uint32Array(length))
  return Array.from(bytes, (b) => PASSWORD_CHARS[b % PASSWORD_CHARS.length]).join('')
}

// "Józef Łukasz-Wiśniewski" → "jozef.lukasz-wisniewski"
const slug = (text: string) =>
  text
    .trim()
    .toLowerCase()
    .replace(/ł/g, 'l')
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/\s+/g, '-')
    .replace(/[^a-z-]/g, '')

// Unikalny login z imienia i nazwiska – jeśli zajęty, dopisuje numer
export const uniqueEmail = (firstName: string, lastName: string, taken: Set<string>) => {
  const base = [slug(firstName), slug(lastName)].filter(Boolean).join('.')
  if (!base) return ''
  let email = `${base}@${LOGIN_DOMAIN}`
  for (let n = 2; taken.has(email); n++) email = `${base}${n}@${LOGIN_DOMAIN}`
  return email
}
