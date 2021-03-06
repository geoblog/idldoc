;+
; Test comment.
;
; @keyword my_keyword comment
;-
function mg_src_root, my_keyword=myKey
;+
; Returns the directory name (with a trailing slash) of the location of the
; source code for the routine that called this function.
;     
; @returns string
;-  
  compile_opt strictarr
  
  traceback = scope_traceback(/structure)
  callingFrame = traceback[n_elements(traceback) - 2L > 0]
  return, file_dirname(callingFrame.filename, /mark_directory)
end
