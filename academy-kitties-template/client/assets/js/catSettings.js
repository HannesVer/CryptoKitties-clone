
var colors = Object.values(allColors())

var defaultDNA = {
    "headcolor" : 10,
    "mouthColor" : 13,
    "eyesColor" : 96,
    "earsColor" : 10,
    //Cattributes
    "eyesShape" : 1,
    "decorationPattern" : 1,
    "decorationMidcolor" : 13,
    "decorationSidescolor" : 13,
    "animation" :  1,
    "lastNum" :  1
    }

// when page load
$( document ).ready(function() {
  $('#dnabody').html(defaultDNA.headColor);
  $('#dnamouth').html(defaultDNA.mouthColor);
  $('#dnaeyes').html(defaultDNA.eyesColor);
  $('#dnaears').html(defaultDNA.earsColor);

  renderCat(defaultDNA)
});

function defaultCat(){
    renderCat(defaultDNA)
}

function randomDNA(){
    var dnaStr = String(Math.floor(Math.random()*1E16))
    //Colors
    var dna = {
    "headcolor" : dnaStr.substring(0, 2),
    "mouthColor" : dnaStr.substring(2, 4),
    "eyesColor" : dnaStr.substring(4, 6),
    "earsColor" : dnaStr.substring(6, 8),
    //Cattributes
    "eyesShape" : dnaStr.substring(8,9) % 8 + 1    ,
    "decorationPattern" : dnaStr.substring(9, 10)  % 8 + 1,
    "decorationMidcolor" : dnaStr.substring(10, 12),
    "decorationSidescolor" : dnaStr.substring(12, 14),
    "animation" :  dnaStr.substring(14, 15) % 6 + 1,
    "lastNum" :  dnaStr.substring(15, 16)
    }

    return dna
}

//Random cat DNA
function randomCat(){
 var dna = randomDNA()
    //Rendering Cat
   renderCat(dna)
}

function getDna(){
    var dna = ''
    dna += $('#dnabody').html()
    dna += $('#dnamouth').html()
    dna += $('#dnaeyes').html()
    dna += $('#dnaears').html()
    dna += $('#dnashape').html()
    dna += $('#dnadecoration').html()
    dna += $('#dnadecorationMid').html()
    dna += $('#dnadecorationSides').html()
    dna += $('#dnadanimation').html()
    dna += $('#dnaspecial').html()

    return dna
}

function renderCat(dna){
    headColor(colors[dna.headcolor],dna.headcolor)
    $('#bodycolor').val(dna.headcolor)
}

// Changing cat colors
$('#bodycolor').change(()=>{
    var colorVal = $('#bodycolor').val()
    headColor(colors[colorVal],colorVal)
})
