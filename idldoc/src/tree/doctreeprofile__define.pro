; docformat = 'rst'

;+
; This class represents a information about .pro file.
; 
; :Properties:
;    basename : get, set, type=string
;       basename of filename
;    has_main_level : get, set, type=boolean
;       true if the file has a main-level program at the end
;    is_batch : get, set, type=boolean
;       true if the file is a batch file
;    comments : get, set, type=object
;       text tree hierarchy for file level comments
;    n_routines : get, type=integer
;       number of routines in the file
;    routines : get, type=object
;       list object containing routine objects in file
;-


;+
; Get properties.
;-
pro doctreeprofile::getProperty, basename=basename, $
                                 has_main_level=hasMainLevel, $
                                 is_batch=isBatch, $
                                 is_class=isClass, class=class, $
                                 comments=comments, $
                                 n_routines=nRoutines, routines=routines, $
                                 n_lines=nLines, directory=directory
  compile_opt strictarr
  
  if (arg_present(basename)) then basename = self.basename
  if (arg_present(directory)) then directory = self.directory
  if (arg_present(hasMainLevel)) then hasMainLevel = self.hasMainLevel
  if (arg_present(isBatch)) then isBatch = self.isBatch 
  if (arg_present(isClass)) then isClass = self.isClass   
  if (arg_present(class)) then class = self.class  
  if (arg_present(comments)) then comments = self.comments
  if (arg_present(nRoutines)) then nRoutines = self.routines->count()
  if (arg_present(routines)) then routines = self.routines
  if (arg_present(nLines)) then nLines = self.nLines
end


;+
; Set properties.
;-
pro doctreeprofile::setProperty, code=code, has_main_level=hasMainLevel, $
                                 is_hidden=isHidden, is_private=isPrivate, $
                                 is_batch=isBatch, comments=comments, $
                                 modification_time=mTime, n_lines=nLines, $ 
                                 format=format, markup=markup, $
                                 examples=examples, $
                                 author=author, copyright=copyright, $
                                 history=history, version=version                                 
  compile_opt strictarr
  
  if (n_elements(code) gt 0) then begin
    ; translate strarr to parse tree, also mark comments
    
    proFileParser = self.system->getParser('profile')
    self.code = obj_new('MGtmTag')
      
    for l = 0L, n_elements(code) - 1L do begin
      regularLines = proFileParser->_stripComments(code[l], comments=commentsLines)
      
      self.code->addChild, obj_new('MGtmText', text=regularLines)
      
      commentsNode = obj_new('MGtmTag', type='comments')
      self.code->addChild, commentsNode
      commentsNode->addChild, obj_new('MGtmText', text=commentsLines)
      self.code->addChild, obj_new('MGtmTag', type='newline')
    endfor  
  endif
  
  if (n_elements(isHidden) gt 0) then self.isHidden = isHidden
  if (n_elements(isPrivate) gt 0) then self.isPrivate = isPrivate
  
  if (n_elements(hasMainLevel) gt 0) then self.hasMainLevel = hasMainLevel
  if (n_elements(isBatch) gt 0) then self.isBatch = isBatch
  if (n_elements(comments) gt 0) then begin
    if (obj_valid(self.comments)) then begin
      parent = obj_new('MGtmTag')
      parent->addChild, self.comments
      parent->addChild, comments
      self.comments = parent
    endif else self.comments = comments
  endif
  if (n_elements(format) gt 0) then self.format = format
  if (n_elements(markup) gt 0) then self.markup = markup
  if (n_elements(nLines) gt 0) then self.nLines = nLines
  if (n_elements(mTime) gt 0) then self.modificationTime = mTime
  
  if (n_elements(examples) gt 0) then self.examples = examples
  
  ; "author info" attributes
  if (n_elements(author) gt 0) then begin
    self.hasAuthorInfo = 1B
    self.author = author
  endif

  if (n_elements(copyright) gt 0) then begin
    self.hasAuthorInfo = 1B
    self.copyright = copyright
  endif
  
  if (n_elements(history) gt 0) then begin
    self.hasAuthorInfo = 1B
    self.history = history
  endif  

  if (n_elements(version) gt 0) then begin
    self.hasAuthorInfo = 1B
    self.version = version
  endif    
end


;+
; Get variables for use with templates.
;
; :Returns: variable
; :Params:
;    name : in, required, type=string
;       name of variable
;
; :Keywords:
;    found : out, optional, type=boolean
;       set to a named variable, returns if variable name was found
;-
function doctreeprofile::getVariable, name, found=found
  compile_opt strictarr
  
  found = 1B
  case strlowcase(name) of
    'basename': return, self.basename
    'local_url': return, file_basename(self.basename, '.pro') + '.html'
    'source_url': return, file_basename(self.basename, '.pro') + '-code.html'
    'direct_source_url': return, file_basename(self.basename)
    'code': return, self.system->processComments(self.code)
    
    'is_batch': return, self.isBatch
    'has_main_level': return, self.hasMainLevel
    'is_class': return, self.isClass
    'class': return, self.class
    'is_private': return, self.isPrivate
    
    'modification_time': return, self.modificationTime
    'n_lines': return, mg_int_format(self.nLines)
    'format': return, self.format
    'markup': return, self.markup

    'has_examples': return, obj_valid(self.examples)
    'examples': return, self.system->processComments(self.examples) 
        
    'has_comments': return, obj_valid(self.comments)
    'comments': return, self.system->processComments(self.comments)       
    'comments_first_line': begin
        ; if no file comments, but there is only one routine then return the
        ; first line of the routine's comments
        if (~obj_valid(self.comments)) then begin
          if (self.routines->count() eq 1) then begin
            routine = self.routines->get(position=0L)
            return, routine->getVariable('comments_first_line', found=found)
          endif else return, ''
        endif
        
        comments = self.system->processComments(self.comments)             
        
        nLines = n_elements(comments)
        line = 0L
        while (line lt nLines) do begin
          pos = stregex(comments[line], '\.( |$)')
          if (pos ne -1L) then break
          line++
        endwhile  
        
        if (pos eq -1L) then return, comments[0L:line-1L]
        if (line eq 0L) then return, strmid(comments[line], 0L, pos + 1L)
        
        return, [comments[0L:line-1L], strmid(comments[line], 0L, pos + 1L)]
      end
          
    'n_routines' : return, self.routines->count()
    'routines' : return, self.routines->get(/all)
    'n_visible_routines': begin
        nVisible = 0L
        for r = 0L, self.routines->count() - 1L do begin
          routine = self.routines->get(position=r)          
          nVisible += routine->isVisible()          
        endfor
        return, nVisible
      end
    'visible_routines': begin        
        routines = self.routines->get(/all, count=nRoutines)
        if (nRoutines eq 0L) then return, -1L
        
        isVisibleRoutines = bytarr(nRoutines)
        for r = 0L, nRoutines - 1L do begin
          isVisibleRoutines[r] = routines[r]->isVisible()
        endfor
        
        ind = where(isVisibleRoutines eq 1B, nVisibleRoutines)
        if (nVisibleRoutines eq 0L) then return, -1L
        
        return, routines[ind]
      end
    
    'has_author_info': return, self.hasAuthorInfo
    
    'has_author': return, obj_valid(self.author)
    'author': return, self.system->processComments(self.author)

    'has_copyright': return, obj_valid(self.copyright)
    'copyright': return, self.system->processComments(self.copyright)
    
    'has_history': return, obj_valid(self.history)
    'history': return, self.system->processComments(self.history)

    'has_version': return, obj_valid(self.version)
    'version': return, self.system->processComments(self.version)

    'index_name': return, self.basename
    'index_type': begin
        return, '.pro file in ' + self.directory->getVariable('location') + ' directory'
      end      
    'index_url': begin
        self.directory->getProperty, url=dirUrl
        return, dirUrl + file_basename(self.basename, '.pro') + '.html'
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
; Uses file hidden/private attributes and system wide user/developer level to
; determine if this file should be visible.
;
; :Returns: boolean
;-
function doctreeprofile::isVisible
  compile_opt strictarr
  
  if (self.isHidden) then return, 0B
  
  ; if creating user-level docs and private then not visible
  self.system->getProperty, user=user
  if (self.isPrivate && user) then return, 0B
  
  return, 1B
end


;+
; Add a routine to the list of routines in the file.
; 
; :Params:
;    routine : in, required, type=object
;       routine object
;-
pro doctreeprofile::addRoutine, routine
  compile_opt strictarr
  
  self.routines->add, routine
end


;+
; Do any analysis necessary on information gathered during the "parseTree"
; phase.
;-
pro doctreeprofile::process
  compile_opt strictarr
  
  for r = 0L, self.routines->count() - 1L do begin
    routine = self.routines->get(position=r)
    routine->markArguments
    routine->checkDocumentation
  endfor
end


pro doctreeprofile::generateOutput, outputRoot, directory
  compile_opt strictarr
  
  ; don't produce output if not visible
  if (~self->isVisible()) then return
  
  self.system->print, '  Generating output for ' + self.basename + '...'

  proFileTemplate = self.system->getTemplate('profile')
  
  outputDir = outputRoot + directory
  outputFilename = outputDir + file_basename(self.basename, '.pro') + '.html'
  
  proFileTemplate->reset
  proFileTemplate->process, self, outputFilename  
  
  self.system->getProperty, nosource=nosource
  if (nosource) then return
  
  ; chromocoded version of the source code
  sourceTemplate = self.system->getTemplate('source')
  
  outputFilename = outputDir + file_basename(self.basename, '.pro') + '-code.html'
  
  sourceTemplate->reset
  sourceTemplate->process, self, outputFilename    
  
  ; direct version of the source code
  file_copy, self.fullpath, outputDir + file_basename(self.basename), $
             /allow_same, /overwrite
end


;+
; Free resources.
;-
pro doctreeprofile::cleanup
  compile_opt strictarr
  
  obj_destroy, self.routines
  obj_destroy, [self.author, self.copyright, self.history]
  obj_destroy, self.code
end


;+
; Create file tree object.
;
; :Returns: 1 for success, 0 for failure
;
; :Keywords:
;    basename : in, required, type=string
;       basename of the .pro file
;    directory : in, required, type=object
;       directory tree object
;    system : in, required, type=object
;       system object
;    fullpath : in, required, type=string
;       full filename of the .pro file
;-
function doctreeprofile::init, basename=basename, directory=directory, $
                               system=system, fullpath=fullpath
  compile_opt strictarr
  
  self.basename = basename
  self.directory = directory
  self.system = system
  self.fullpath = fullpath
  
  self.isClass = strlowcase(strmid(self.basename, 11, /reverse_offset)) eq '__define.pro'
  if (self.isClass) then begin  
    classname = strmid(self.basename, 0, strlen(self.basename) - 12)
    self.system->getProperty, classes=classes
    class = classes->get(strlowcase(classname), found=found)
    if (found) then begin
      self.class = class
      self.class->setProperty, pro_file=self, classname=classname
    endif else begin
      self.class = obj_new('DOCtreeClass', $
                           classname, $
                           pro_file=self, $
                           system=self.system)
    endelse
  endif 
  
  self.routines = obj_new('MGcoArrayList', type=11)
  
  self.system->createIndexEntry, self.basename, self
  self.system->print, '  Parsing ' + self.basename + '...'
  
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
;    hasMainLevel
;       true if the file has a main level program at the end
;    isBatch
;       true if the file is a batch file
;    routines 
;       list of routine objects
;-
pro doctreeprofile__define
  compile_opt strictarr
  
  define = { DOCtreeProFile, $
             system: obj_new(), $
             directory: obj_new(), $
             
             fullpath: '', $
             basename: '', $
             code: obj_new(), $
             
             hasMainLevel: 0B, $
             isBatch: 0B, $
             isClass: 0B, $
             class: obj_new(), $
             
             modificationTime: '', $
             nLines: 0L, $
             format: '', $
             markup: '', $
             
             comments: obj_new(), $
             
             routines: obj_new(), $
             
             isHidden: 0B, $
             isPrivate: 0B, $
             
             examples: obj_new(), $
             
             hasAuthorInfo: 0B, $
             author: obj_new(), $
             copyright: obj_new(), $
             history: obj_new(), $
             version: obj_new() $
           }
end