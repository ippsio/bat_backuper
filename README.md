# bat_backuper

## What is this


An bat file. For backup your folder.
It copis your folder with no compression.

![working_img](https://github.com/ippsio/bat_backuper/blob/master/working_img.png?raw=true "working_img")


## Why no compression.

Work with/at/on too much heavy PC or environment, 
decompressing zip file will be a serious bottole neck(mainly I/O bottle neck), and your PC won't works well.

Restore from raw backup folder is simple. 


## Quick way to backup your folder

1. put gen3.bat to folder that you want to take backup.
  ```
  C:\Users\username\work\folder\  <--- put gen3.bat 
  ```

2. Execute gen3.bat.
  ```
  C:\Users\username\work\folder> gen3.bat [Enter]
  ```

3. Backup will be created at C:\Users\username\work.
  ```
  C:\Users\username\work> dir
  2016/04/08  18:53    <DIR>          folder
  2016/06/21  21:19    <DIR>          bk_folder_1 <-- Created!!
  ```

## Quick way to restore your backup

1. Rename main folder name.
  ```
  C:\Users\username\work\folder> move folder folder_broken[Enter]
  ```

2. Rename backup folder.
  ```
  C:\Users\username\work\folder> move bk_folder_1 folder [Enter]
  ```

## So, what is gen"3"?

This number is a setting.
gen3.bat creates backup folder for 3 generations.
So rename this bat file to gen6.bat, then this creates backup folder for 6 generations.


## Dependencies?
No java needed. No ruby needed. No python needed.
Only needs Windows(robocopy). This is 100% pure bat.



