fs      = require 'fs'
Botkit  = require('botkit')
request = require('request')
request = request.defaults({jar: true})

BOT_NAME       = "padhi"
BOT_ICON_EMOJI = ":chart_with_upwards_trend:"


# Expect a SLACK_TOKEN environment variable
slackToken = process.env.SLACK_TOKEN
if !slackToken
    console.error 'SLACK_TOKEN is required!'
    process.exit 1


# spawn new bot
controller = Botkit.slackbot()
bot = controller.spawn(token: slackToken)

bot.startRTM (err, bot, payload) ->
    if err then throw new Error('Could not connect to Slack')

controller.on 'bot_channel_join', (bot, message) ->
    bot.reply message, 'Updatemi – just the facts!'

decode = (text) ->
    text = text.replace('&auml;', 'ä')
    text = text.replace('&Auml;', 'Ä')
    text = text.replace('&ouml;', 'ö')
    text = text.replace('&Ouml;', 'Ö')
    text = text.replace('&uuml;', 'ü')
    text = text.replace('&Uuml;', 'Ü')
    text = text.replace('&szlig;', 'ß')
    text = text.replace('&ndash;', '–')
    return text


updatemiDecode = (text) ->
    url_re  = /\[url=(.+?)\](.+?)\[\/url\]/
    wiki_re = /\[wiki=(.+?)\](.+?)\[\/wiki\]/

    matches = url_re.exec(text)
    if matches
        url  = matches[1]
        desc = matches[2]
        text = text.replace url_re, "<#{url}|#{desc}>"

    matches = wiki_re.exec(text)
    if matches
        url  = matches[1]
        desc = matches[2]
        text = text.replace wiki_re, "<#{url}|#{desc}>"

    return text

controller.hears [ 'updatemi (.+?)' ], [ 'direct_mention', 'direct_message'], (bot, message) ->
    LIMIT = 3
    URL = "https://www.updatemi.com/api/me/feed?_format=json&filters=topPromotionDate>:date%7C0&limit=#{LIMIT}&AuthToken=#{process.env.UPDATEMI_TOKEN}"

    request URL, (err, res, body) ->
        updates = JSON.parse body
        answer =
            'username': BOT_NAME
            'icon_emoji': ":newspaper:"
            'attachments': []

        for u in updates
            u.summary = ("• " + updatemiDecode(bp) for bp in u.summary).join("\n")
            answer.attachments.push {
                'fallback': u.headline
                'title': u.headline
                'title_link': u.short_url

                'color': "#c06"
                'thumb_url': u.image.url

                'author': "Updatemi"
                'author_link': "https://www.updatemi.com/"
                'author_icon': "https://www.updatemi.com/favicon-16x16.png"

                'text': u.summary
            }

        bot.reply message, answer


controller.hears 'hilfe', [ 'direct_message', 'direct_mention' ], (bot, message) ->
    help = "So funktioniert’s:\n" +
        "`@#{BOT_NAME}: updatemi` um die jüngsten Nachrichten von Updatemi zu beziehen.\n" +
        "`@#{BOT_NAME}: hilfe` um diese Nachricht zu sehen."
    bot.reply message, help

controller.hears '.*', [ 'direct_message', 'direct_mention' ], (bot, message) ->
    bot.reply message, 'Entschuldige, <@' + message.user + '>, ich weiß nicht genau, was Du meinst. \n'
