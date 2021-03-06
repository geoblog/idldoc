; docformat = 'rst'

;+
; Basic IDL standard library run.
;-
function docltidllib_ut::test_basic
  compile_opt strictarr

  idldoc, root=filepath('lib'), $
          output=filepath('lib-docs', root=self.root), $
          title='Testing IDL standard library', $
          subtitle='Basic test', $
          format_style='idl', $
          n_warnings=nWarnings, error=error, $
          log_file=filepath('idldoc.log', subdir='lib-docs', root=self.root)
          
  assert, error eq 0, 'failed with error ' + !error_state.msg
  assert, nWarnings eq 0, 'failed with warnings'
  
  return, 1
end


;+
; Define instance variables.
;-
pro docltidllib_ut__define
  compile_opt strictarr
  
  define = { DOCltIDLLib_ut, inherits DOCltTestCase }
end