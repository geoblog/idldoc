; docformat = 'rst'

;+
; This class represents a information about .idldoc file.
; 
; :Properties:
;    basename : get, type=string
;       basename of filename
;    comments : set, type=object
;       text markup tree to add to the current tree
;    directory
;       directory tree object that the .idldoc file is located within
;    system
;       system object
;-


;+
; Get properties.
;-
pro doctreeidldocfile::getProperty, basename=basename, directory=directory
  compile_opt strictarr, hidden
  
  if (arg_present(basename)) then basename = self.basename
  if (arg_present(directory)) then directory = self.directory
end


;+
; Set properties.
;-
pro doctreeidldocfile::setProperty, comments=comments
  compile_opt strictarr, hidden

  if (n_elements(comments) gt 0) then begin
    if (obj_valid(self.comments)) then begin
      parent = obj_new('MGtmTag')
      parent->addChild, self.comments
      parent->addChild, comments
      self.comments = parent
    endif else self.comments = comments
  endif
end


;+
; Get variables for use with templates.
;
; :Returns: 
;    variable
;
; :Params:
;    name : in, required, type=string
;       name of variable
;
; :Keywords:
;    found : out, optional, type=boolean
;       set to a named variable, returns if variable name was found
;-
function doctreeidldocfile::getVariable, name, found=found
  compile_opt strictarr, hidden
  
  found = 1B
  case strlowcase(name) of
    'basename': return, self.basename
    'local_url': begin
        self.system->getProperty, extension=outputExtension
        return, file_basename(self.basename, '.idldoc') + '.' + outputExtension
      end
    
    'has_comments': return, obj_valid(self.comments)
    'comments': return, self.system->processComments(self.comments)    
    'comments_first_line': begin
        if (~obj_valid(self.comments)) then return, ''
        comments = self.system->processComments(self.comments) 
        
        nLines = n_elements(comments)
        line = 0
        while (line lt nLines) do begin
          pos = stregex(comments[line], '\.( |$)')
          if (pos ne -1) then break
          line++
        endwhile  
        
        if (pos eq -1) then return, comments[0:line-1]
        if (line eq 0) then return, strmid(comments[line], 0, pos + 1)
        
        return, [comments[0:line-1], strmid(comments[line], 0, pos + 1)]
      end  
    'output_path': begin      
         self.directory->getProperty, url=url     
         self.system->getProperty, extension=ext
         return, url + file_basename(self.basename, '.idldoc') + '.' + ext
       end      
      
    else: begin
        ; search in the system object if the variable is not found here
        var = self.directory->getVariable(name, found=found)
        if (found) then return, var
        
        found = 0B
        return, -1L
      end
  endcase
end


;+
; .idldoc files are always visible.
;
; :Returns: 
;    1 if visible, 0 if not visible.
;-
function doctreeidldocfile::isVisible
  compile_opt strictarr, hidden
  
  return, self.directory->isVisible(/no_check_children)
end


pro doctreeidldocfile::addImageRef, filename
  compile_opt strictarr, hidden
  
  self.imagerefs->add, filename
end


;+
; Generate the output for the .idldoc file.
; 
; :Params:
;    outputRoot : in, required, type=string
;       location of the root of the run
;    directory : in, required, type=string
;       specification of the directory the .idldoc file is in (relative to the 
;       root)
;-
pro doctreeidldocfile::generateOutput, outputRoot, directory
  compile_opt strictarr, hidden
  
  self.system->print, '  Generating output for ' + self.basename
  self.system->getProperty, extension=outputExtension

  ; copy images references in the documentation
  outputDir = outputRoot + directory
  outputFilename = outputDir + file_basename(self.basename, '.pro') + '.' + outputExtension
  
  self.system->getProperty, root=root    
  self.directory->getProperty, location=dirLocation
  fullpath = filepath(self.basename, subdir=dirLocation, root=root)
  for i = 0L, self.imagerefs->count() - 1L do begin
    path = file_dirname(fullpath, /mark_directory)
    filename = self.imagerefs->get(position=i)
    if (file_test(path + filename)) then begin
      _outputDir = file_dirname(outputDir + filename)
      if (~file_test(_outputDir, /directory)) then file_mkdir, _outputDir

      file_copy, path + filename, outputDir + filename, /allow_same, /overwrite
    endif else begin
      self.system->warning, 'image at ' + path + filename + ' not found'
    endelse
  endfor
    
  idldocFileTemplate = self.system->getTemplate('idldocfile')
    
  outputDir = outputRoot + directory
  outputFilename = outputDir + file_basename(self.basename, '.idldoc') + '.' + outputExtension
  
  idldocFileTemplate->reset
  idldocFileTemplate->process, self, outputFilename   
end


;+
; Free resources.
;-
pro doctreeidldocfile::cleanup
  compile_opt strictarr, hidden
  
  obj_destroy, [self.comments, self.imagerefs]
end


;+
; Create file tree object.
;
; :Returns: 
;    1 for success, 0 for failure
;-
function doctreeidldocfile::init, basename=basename, directory=directory, $
                                  system=system
  compile_opt strictarr, hidden
  
  self.basename = basename
  self.directory = directory
  self.system = system

  self.imagerefs = obj_new('MGcoArrayList', type=7, block_size=3)
  
  self.system->getProperty, index_level=indexLevel
  if (indexLevel ge 1L) then self.system->createIndexEntry, self.basename, self
  
  self.system->print, '  Parsing ' + self.basename + '...'
  
  self.system->getProperty, root=root
  self.directory->getProperty, location=location
  
  return, 1
end


;+
; Define instance variables.
; 
; :Fields:
;    directory
;       directory tree object
;    basename
;       basename of file
;    comments
;       comment markup tree
;    system
;       system object
;-
pro doctreeidldocfile__define
  compile_opt strictarr, hidden
  
  define = { DOCtreeIDLdocFile, $
             system: obj_new(), $
             directory: obj_new(), $
             
             basename: '', $
             comments: obj_new(), $
             
             imagerefs: obj_new() $
           }
end