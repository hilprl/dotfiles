# -*- coding: utf-8 -*-

from ranger.api.commands import *

class bulkrename(Command):
    """:bulkrename

    This command opens a list of selected files in an external editor.
    After you edit and save the file, it will generate a shell script
    which does bulk renaming according to the changes you did in the file.

    This shell script is opened in an editor for you to review.
    After you close it, it will be executed.
    """
    def execute(self):
        import sys
        import tempfile
        from ranger.container.file import File
        from ranger.ext.shell_escape import shell_escape as esc
        py3 = sys.version > "3"

        ## CUSTOM: change editor here.
        local_ed='emc'

        # Create and edit the file list
        filenames = [f.basename for f in self.fm.thistab.get_selection()]
        listfile = tempfile.NamedTemporaryFile()

        if py3:
            listfile.write("\n".join(filenames).encode("utf-8"))
        else:
            listfile.write("\n".join(filenames))
        listfile.flush()
        self.fm.execute_file([File(listfile.name)], app=local_ed)
        listfile.seek(0)
        if py3:
            new_filenames = listfile.read().decode("utf-8").split("\n")
        else:
            new_filenames = listfile.read().split("\n")
        listfile.close()
        if all(a == b for a, b in zip(filenames, new_filenames)):
            self.fm.notify("No renaming to be done!")
            return

        # Generate and execute script
        cmdfile = tempfile.NamedTemporaryFile()
        cmdfile.write(b"# This file will be executed when you close the editor.\n")
        cmdfile.write(b"# Please double-check everything, clear the file to abort.\n")
        if py3:
            cmdfile.write("\n".join("mv -vi -- " + esc(old) + " " + esc(new) \
                for old, new in zip(filenames, new_filenames) \
                if old != new).encode("utf-8"))
        else:
            cmdfile.write("\n".join("mv -vi -- " + esc(old) + " " + esc(new) \
                for old, new in zip(filenames, new_filenames) if old != new))
        cmdfile.flush()
        self.fm.execute_file([File(cmdfile.name)], app=local_ed)
        self.fm.run(['/bin/sh', cmdfile.name], flags='w')
        cmdfile.close()