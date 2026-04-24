return {
  source_png  = "kobold_7.png",
  source_meta = "kobold_7.txt",

  -- Character set in spritesheet order (from kobold_7.txt "Character set:" line)
  sheet_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,;:?!\"'+-=*%_()[]{}~#&@©®™°^`|/\\<>…€$£¢¿¡\u{201C}\u{201D}\u{2018}\u{2019}«»‹›„‚·•ÀÁÂÄÃÅĄÆÇĆÐÈÉÊËĘĞÌÍÎÏİŁÑŃÒÓÔÖÕŐØŒŚŞẞÞÙÚÛÜŰÝŸŹŻàáâäãåąæçćðèéêëęğìíîïıłñńòóôöõőøœśşßþùúûüűýÿźżАБВГҐДЕЁЄЖЗИІЇЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгґдеёєжзиіїйклмнопрстуфхцчшщъыьэюя",

  -- ASCII printable range (32–127) for Picotron output
  -- Space (32) is not in the spritesheet; a blank glyph is substituted automatically
  p8_chars = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~",

  base_width  = 8,
  height      = 16,
  x_offset    = 0,
  y_offset    = 0,

  slice_x_offset = 0,
  slice_y_offset = 5,

  output_font = "kobold.font",

  manual_widths = {},
}
