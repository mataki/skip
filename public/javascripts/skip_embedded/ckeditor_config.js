/*
 Copyright (c) 2003-2009, CKSource - Frederico Knabben. All rights reserved.
 For licensing, see LICENSE.html or http://ckeditor.com/license
 */

CKEDITOR.editorConfig = function( config )
{
    config.contentsCss = CKEDITOR.getUrl( '/stylesheets/skip_embedded/ckeditor_area.css' );

    config.toolbar_Entry = [
        ['Cut','Copy','Paste','PasteText','PasteFromWord','-','Print', 'SpellChecker', 'Scayt'],
        ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
        '/',
        ['Bold','Italic','Underline','Strike'],
        ['NumberedList','BulletedList','-','Outdent','Indent','Blockquote'],
        ['JustifyLeft','JustifyCenter','JustifyRight','JustifyBlock'],
        ['TextColor','BGColor'],
        ['Table','HorizontalRule','Smiley','SpecialChar'],
        '/',
        ['Styles','Format','Font','FontSize'],
        ['Link','Unlink','Anchor'],
        ['Source','Preview'],
        ['Maximize', 'ShowBlocks','-','About']
    ];

    config.toolbar_Simple = [
        ['Undo','Redo'],
        ['Bold','Italic','Underline','Strike','RemoveFormat'],
        ['TextColor','BGColor','Smiley'],
        '/',
        ['Font','Format','FontSize']           // No comma for the last row.
    ];

    config.linkShowAdvancedTab = false ;

    config.font_names = [
        "ＭＳＰゴシック/'ＭＳＰゴシック';",
        "ＭＳ Ｐ明朝/ＭＳ Ｐ明朝;",
        "ＭＳ ゴシック/ＭＳ ゴシック;",
        'ＭＳ 明朝/ＭＳ 明朝;',
        'MS UI Gothic/MS UI Gothic;',
        'Arial/Arial, Helvetica, sans-serif;',
        'Comic Sans MS/Comic Sans MS, cursive;',
        'Courier New/Courier New, Courier, monospace;',
        'Georgia/Georgia, serif;',
        'Lucida Sans Unicode/Lucida Sans Unicode, Lucida Grande, sans-serif;',
        'Tahoma/Tahoma, Geneva, sans-serif;',
        'Times New Roman/Times New Roman, Times, serif;',
        'Trebuchet MS/Trebuchet MS, Helvetica, sans-serif;',
        'Verdana/Verdana, Geneva, sans-serif'
    ].join('');
};
