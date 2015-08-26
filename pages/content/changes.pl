{
    layout => 'sidebar',
    scripts => [ "/stc/common.js" ],
    title => 'Changelog',
    content => read_then_close(*DATA)
}

__DATA__
<p>
  This is a list of larger user-visible changes, feature additions, etc.
  For a tedious list including minor bugfixes and cosmetic changes, see the
  <a href="https://github.com/bcgraham/terra-mystica/commits/master">version control logs</a>. 
  This lightly-edited fork of <a href="https://www.snellman.net/">Juho Snellman's</a> 
  <a href="https://github.com/jsnell/terra-mystica/">open-source implementation</a>.
</p>

<div id="changes" class="changelog"></div>

<script language="javascript">
  fetchChangelog(function(data) {
      showChangelog(data, $("changes"), "Changes", {"change": true})
  });
</script>
