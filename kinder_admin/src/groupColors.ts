// Pastelowe kolory grup – przydzielane po kolejności grup (alfabetycznie)
export const groupPalette = [
  { bg: '#ede9fe', text: '#5b21b6', avatar: '#c4b5fd' }, // fiolet
  { bg: '#ffedd5', text: '#9a3412', avatar: '#fdba74' }, // brzoskwinia
  { bg: '#dcfce7', text: '#166534', avatar: '#86efac' }, // mięta
  { bg: '#e0f2fe', text: '#075985', avatar: '#7dd3fc' }, // błękit
  { bg: '#fce7f3', text: '#9d174d', avatar: '#f9a8d4' }, // róż
  { bg: '#fef9c3', text: '#854d0e', avatar: '#fde047' }, // żółty
]

export const noGroupColor = { bg: '#f5f5f4', text: '#57534e', avatar: '#e7e5e4' }

export const groupColor = (groups: { id: string }[], groupId: string | null) => {
  const i = groups.findIndex((g) => g.id === groupId)
  return (i < 0 ? undefined : groupPalette[i % groupPalette.length]) ?? noGroupColor
}
