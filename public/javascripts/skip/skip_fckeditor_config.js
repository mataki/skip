FCKConfig.Plugins.Add( 'autogrow' ) ;
FCKConfig.Plugins.Add( 'dragresizetable' );
FCKConfig.AutoGrowMax = 1000 ;

FCKConfig.BodyId = 'fckedit' ;
FCKConfig.BodyClass = 'fck' ;

FCKConfig.DefaultLanguage               = 'ja' ;
FCKConfig.SkinPath = FCKConfig.BasePath + 'skins/silver/';

FCKConfig.ToolbarSets["Custom"] = [
        ['Cut','Copy','Paste','PasteText','PasteWord'],
        ['Undo','Redo','RemoveFormat'],
        ['Bold','Italic','Underline','StrikeThrough'],
        ['OrderedList','UnorderedList'],
        ['JustifyLeft','JustifyCenter','JustifyRight','JustifyFull'],
        ['Table','Rule','Smiley'],
        '/',
        ['FontFormat','FontSize'],
        ['TextColor','BGColor'],
        ['Link','Unlink'],
        ['Source','Preview'],
        ['FitWindow','ShowBlocks','-','About']          // No comma for the last row.
] ;

FCKConfig.LinkBrowser = false ;
FCKConfig.ImageBrowser = false ;
FCKConfig.FlashBrowser = false ;
FCKConfig.LinkUpload = false ;
FCKConfig.ImageUpload = false ;
FCKConfig.FlashUpload = false ;

