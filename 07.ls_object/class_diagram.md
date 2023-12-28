```mermaid
classDiagram
  class LsCommand {
    -options
    +initialize()
    +show()
  }

  class DirItem {
    +name
    +file_items
    +initialize()
    -collect_files()
  }

  class FileItem {
    +path
    -stat
    +initialize()
    +stat()
    -build_stat()
  }

  class DisplayData {
    -dir_items
    -file_items
    -non_exist_items
    -options
    +initialize()
    +result()
    -sort_non_exist_items()
    -sort_dir_items()
    -sort_file_items()
    -format()
    -store_files_in_column()
    -calc_columns_width()
    -unite_columns_to_rows()
    -count_character()
    -rjust_by_displayed_width()
  }

  class LongDisplayData {
    -count_total_blocks()
    -count_owner_char_length()
    -count_group_char_length()
    -build_row()
    -convert_ftype_to_mark()
    -convert_mode_to_permissions()
  }

  LsCommand *-- DirItem
  LsCommand *-- FileItem
  DirItem *-- FileItem
  LsCommand ..> DisplayData
  LsCommand ..> LongDisplayData
  LongDisplayData --|> DisplayData
```
